/**
 * STAGING ONLY — fills the database with test data that covers every case in the app.
 * Running it again wipes the data tables and starts fresh.
 *
 *   npm run db:seed:staging
 *
 * Test accounts (all customers use password `Password1`, every verification code is 123456):
 *   hello@appname.com     Main demo user — 3 addresses (Clifton home), cards, orders in every status
 *   new@appname.com       Brand-new user — no addresses, no cards, no orders (empty states)
 *   far@appname.com       Lives in Quetta — no stores in range ("not in your area yet")
 *   lahore@appname.com    Lives in Lahore — only sees the Lahore stores
 *   pending@appname.com   Signed up but never verified — sign-in asks for the code
 *   blocked@appname.com   Suspended account — sign-in is refused
 *   admin@kamkaj.app      Admin panel (password Admin@12345)
 *   staff@kamkaj.app      Admin panel, staff role (password Staff@12345)
 */
import * as bcrypt from 'bcryptjs';
import { sql } from 'drizzle-orm';
import { drizzle } from 'drizzle-orm/node-postgres';
import { Pool } from 'pg';
import * as schema from '../src/db/schema';
import { distanceKm } from '../src/db/geo';

const {
  addresses,
  appSettings,
  categories,
  orderEvents,
  orderItems,
  orders,
  paymentMethods,
  products,
  rides,
  services,
  storeCategories,
  stores,
  users,
  vehicleTypes,
} = schema;

type OrderStatus = schema.OrderStatus;
const pkr = (major: number) => Math.round(major * 100);
const img = (seed: string) => `https://picsum.photos/seed/kamkaj-${seed}/800/600`;
const DAY = 24 * 60 * 60 * 1000;
const ago = (days: number, hours = 0) => new Date(Date.now() - days * DAY - hours * 60 * 60 * 1000);

// Deterministic pseudo-random numbers so every seed produces the same data.
let rngState = 42;
const rand = () => ((rngState = (rngState * 1103515245 + 12345) % 2 ** 31) / 2 ** 31);
const pick = <T>(list: T[]) => list[Math.floor(rand() * list.length)];

// ───────────────────────────── Categories (same ids/icons as the app) ─────────────────────────────

type Tint = 'red' | 'green' | 'yellow' | 'blue' | 'purple';
const CATEGORY_ROWS: [string, string, string, string, Tint?, boolean?][] = [
  ['food', 'Food', '42 Stores', 'food', 'red', true],
  ['grocery', 'Grocery', '12 Markets', 'grocery', 'green', true],
  ['pharmacy', 'Pharmacy', '8 Locations', 'pharmacy', 'red', true],
  ['flowers', 'Flowers', '7 Florists', 'flowers', 'yellow', true],
  ['pets', 'Pets', '10 Shops', 'pets'],
  ['bakery', 'Bakery', '15 Bakeries', 'bakery', 'yellow'],
  ['alcohol', 'Beverages', '22 Outlets', 'drinks', 'green'],
  ['gifts', 'Gifts', '14 Shops', 'gifts', 'yellow'],
  ['household', 'Household', 'Essentials for home life', 'household'],
  ['essentials', 'Essentials', '18 Stores', 'essentials'],
  ['electronics', 'Electronics', '9 Tech Hubs', 'electronics', 'green'],
  ['home_decor', 'Home Decor', '12 Studios', 'home_decor', 'yellow'],
  ['toys', 'Toys & Games', '7 Shops', 'toys', 'yellow'],
  ['sports', 'Sports', '11 Outlets', 'sports'],
  ['healthcare', 'Healthcare', '14 Clinics', 'healthcare'],
  ['books', 'Books & Media', '6 Bookstores', 'books'],
  ['hardware', 'Hardware', '9 Centers', 'hardware'],
  ['beauty', 'Beauty & Spa', '12 Salons', 'beauty'],
  ['pet_grooming', 'Pet Grooming', '5 Parlors', 'pets', 'green'],
  ['stationery', 'Stationery', '8 Shops', 'stationery', 'yellow'],
  ['laundry', 'Laundry', '10 Services', 'laundry'],
  ['baby_kids', 'Baby & Kids', '7 Boutiques', 'baby'],
  ['party', 'Party Supplies', '4 Shops', 'party', 'yellow'],
  ['garden', 'Garden', '6 Centers', 'garden', 'yellow'],
  ['office', 'Office Hub', '9 Hubs', 'office'],
  ['meat', 'Meat & Seafood', '12 Butchers', 'meat'],
  ['organic', 'Organic & Farm', '4 Farms', 'organic', 'green'],
  ['dessert', 'Dessert & Sweets', '10 Shops', 'dessert'],
  ['coffee', 'Coffee & Tea', '20 Cafes', 'coffee', 'yellow'],
  ['tailor', 'Tailor', '6 Services', 'tailor'],
  ['shoe_repair', 'Shoe Repair', '4 Shops', 'shoe', 'green'],
  ['key_cutting', 'Key Cutting', '9 Locations', 'key', 'yellow'],
  ['photo', 'Photo Studio', '5 Studios', 'photo'],
  ['dry_cleaning', 'Dry Cleaning', '11 Shops', 'laundry'],
  ['gym', 'Gym & Fitness', '11 Centers', 'fitness', 'green'],
  ['yoga', 'Yoga & Pilates', '8 Studios', 'yoga'],
  ['auto_parts', 'Auto Parts', '6 Stores', 'auto', 'yellow'],
  ['car_wash', 'Car Wash', '7 Services', 'car_wash'],
  ['bike', 'Bike Shop', '5 Shops', 'bike', 'green'],
  ['music', 'Music', '6 Stores', 'music', 'yellow'],
  ['art', 'Art Supplies', '10 Shops', 'art', 'yellow'],
  ['flower_shop', 'Flower Shop', '13 Florists', 'flowers'],
  ['home_cleaning', 'Home Cleaning', '15 Services', 'cleaning', 'green'],
  ['electrician', 'Electrician', '9 Experts', 'electrician'],
  ['plumber', 'Plumber', '12 Experts', 'plumber', 'yellow'],
];

// ───────────────────────────── Stores ─────────────────────────────

interface SeedStore {
  id: string;
  name: string;
  categoryLabel: string;
  tagline?: string;
  address: string;
  city: string;
  lat: number;
  lng: number;
  radius: number;
  rating: number;
  deliveryTime: string;
  deliveryFee: number;
  hours: [string, string] | null;
  sections: string[];
  categories: string[];
  featured?: boolean;
  active?: boolean;
  /** What this store is here to test. */
  note: string;
}

const STORES: SeedStore[] = [
  // Karachi — near Clifton (main demo user's home)
  { id: 's_corner_bakery', name: 'The Corner Bakery', categoryLabel: 'Breads & Pastries', tagline: 'Local Favorite', address: 'Shop 4, Block 5, Clifton', city: 'Karachi', lat: 24.815, lng: 67.0285, radius: 6, rating: 4.9, deliveryTime: '20-30 min', deliveryFee: pkr(100), hours: ['08:00', '22:00'], sections: ['Pastries', 'Bread', 'Coffee', 'Sandwiches'], categories: ['bakery', 'food', 'dessert'], featured: true, note: 'Featured + nearby, full menu' },
  { id: 's_daily_grind', name: 'The Daily Grind', categoryLabel: 'Cafe', address: 'Boat Basin, Block 5, Clifton', city: 'Karachi', lat: 24.82, lng: 67.025, radius: 5, rating: 4.8, deliveryTime: '15-20 min', deliveryFee: pkr(100), hours: ['07:00', '23:30'], sections: ['Coffee', 'Tea', 'Snacks'], categories: ['coffee', 'food'], note: 'Nearby cafe' },
  { id: 's_main_st_flowers', name: 'Main St. Flowers', categoryLabel: 'Boutique Florist', address: 'Zamzama Boulevard, DHA Phase 5', city: 'Karachi', lat: 24.813, lng: 67.039, radius: 8, rating: 4.7, deliveryTime: '10-20 min', deliveryFee: pkr(150), hours: ['10:00', '20:00'], sections: ['Bouquets', 'Plants', 'Gifts'], categories: ['flowers', 'flower_shop', 'gifts'], featured: true, note: 'Featured florist' },
  { id: 's_green_valley', name: 'Green Valley Organics', categoryLabel: 'Groceries', address: 'Khayaban-e-Ittehad, DHA Phase 2', city: 'Karachi', lat: 24.832, lng: 67.056, radius: 7, rating: 4.5, deliveryTime: '25-35 min', deliveryFee: pkr(100), hours: ['09:00', '23:00'], sections: ['Fruit', 'Vegetables', 'Dairy', 'Pantry'], categories: ['grocery', 'organic', 'essentials'], note: 'Grocery with an out-of-stock item' },
  { id: 's_night_owl', name: 'Night Owl Desserts', categoryLabel: 'Late-night sweets', address: 'Bukhari Commercial, DHA Phase 6', city: 'Karachi', lat: 24.7925, lng: 67.065, radius: 6, rating: 4.6, deliveryTime: '25-40 min', deliveryFee: pkr(120), hours: ['18:00', '03:00'], sections: ['Cakes', 'Ice Cream'], categories: ['dessert', 'food'], note: 'Open overnight only — closed during the day' },
  { id: 's_morning_bakes', name: 'Morning Bakes', categoryLabel: 'Breakfast', address: 'Khadda Market, DHA Phase 5', city: 'Karachi', lat: 24.8075, lng: 67.0445, radius: 5, rating: 4.4, deliveryTime: '20-30 min', deliveryFee: pkr(80), hours: ['06:00', '10:00'], sections: ['Breakfast'], categories: ['bakery', 'food'], note: 'Closed most of the day — test "store closed" at checkout' },
  // Karachi — central / east
  { id: 's_springfield', name: 'Springfield Green Grocer', categoryLabel: 'Fresh Produce', address: 'Bahadurabad Chowrangi', city: 'Karachi', lat: 24.8826, lng: 67.07, radius: 8, rating: 4.8, deliveryTime: '15-25 min', deliveryFee: pkr(100), hours: ['08:00', '23:00'], sections: ['Fruit', 'Vegetables'], categories: ['grocery', 'organic'], featured: true, note: 'Featured grocer (Bahadurabad)' },
  { id: 's_careplus', name: 'CarePlus Pharmacy', categoryLabel: 'Pharmacy • 24/7', address: 'Tariq Road, PECHS Block 2', city: 'Karachi', lat: 24.869, lng: 67.06, radius: 9, rating: 4.6, deliveryTime: '20-30 min', deliveryFee: pkr(60), hours: null, sections: ['Medicines', 'Personal Care', 'Baby Care'], categories: ['pharmacy', 'healthcare', 'essentials', 'baby_kids'], featured: true, note: 'Open 24/7 (no hours)' },
  { id: 's_karachi_meats', name: 'Karachi Fresh Meats', categoryLabel: 'Butcher', address: 'Shaheed-e-Millat Road, Bahadurabad', city: 'Karachi', lat: 24.883, lng: 67.069, radius: 6, rating: 4.3, deliveryTime: '30-45 min', deliveryFee: pkr(150), hours: ['09:00', '21:00'], sections: ['Mutton', 'Beef', 'Chicken', 'Seafood'], categories: ['meat', 'food'], note: 'Central butcher' },
  { id: 's_byte_tech', name: 'Byte Tech Hub', categoryLabel: 'Electronics', address: 'Abdullah Haroon Road, Saddar', city: 'Karachi', lat: 24.8556, lng: 67.0186, radius: 10, rating: 4.2, deliveryTime: '45-60 min', deliveryFee: pkr(200), hours: ['11:00', '21:00'], sections: ['Accessories', 'Audio', 'Chargers'], categories: ['electronics'], note: 'Electronics (Saddar)' },
  { id: 's_paws', name: 'Paws & Whiskers', categoryLabel: 'Pet Store', address: 'Block 13-D, Gulshan-e-Iqbal', city: 'Karachi', lat: 24.918, lng: 67.0971, radius: 7, rating: 4.7, deliveryTime: '30-40 min', deliveryFee: pkr(120), hours: ['10:00', '22:00'], sections: ['Food', 'Toys', 'Grooming'], categories: ['pets', 'pet_grooming'], note: 'Only reachable from Gulshan (work/other address)' },
  { id: 's_stationery_corner', name: 'Stationery Corner', categoryLabel: 'Stationery', address: 'Urdu Bazaar, Saddar', city: 'Karachi', lat: 24.8575, lng: 67.0145, radius: 8, rating: 4.0, deliveryTime: '30-45 min', deliveryFee: pkr(100), hours: ['10:00', '20:00'], sections: [], categories: ['stationery', 'office', 'books'], note: 'No products — test empty store page' },
  { id: 's_nazimabad_hardware', name: 'Nazimabad Hardware', categoryLabel: 'Hardware', address: 'Block H, North Nazimabad', city: 'Karachi', lat: 24.942, lng: 67.036, radius: 4, rating: 4.1, deliveryTime: '40-60 min', deliveryFee: pkr(200), hours: ['09:00', '19:00'], sections: ['Tools', 'Electrical'], categories: ['hardware'], note: 'Small 4 km radius — hidden from Clifton/Saddar' },
  { id: 's_malir_farm', name: 'Malir Farm Store', categoryLabel: 'Farm Produce', address: 'Malir Cantt', city: 'Karachi', lat: 24.893, lng: 67.205, radius: 5, rating: 4.4, deliveryTime: '35-50 min', deliveryFee: pkr(150), hours: ['07:00', '19:00'], sections: ['Dairy', 'Eggs'], categories: ['organic', 'grocery'], note: '~18 km from Clifton — outside the 10 km search radius' },
  { id: 's_old_town', name: 'Old Town Grocers', categoryLabel: 'Groceries', address: 'Burns Road, Saddar', city: 'Karachi', lat: 24.858, lng: 67.022, radius: 6, rating: 3.9, deliveryTime: '25-35 min', deliveryFee: pkr(100), hours: ['08:00', '22:00'], sections: ['Pantry'], categories: ['grocery'], active: false, note: 'Inactive — must never appear in the app' },
  // Lahore
  { id: 's_gulberg_bakehouse', name: 'Gulberg Bakehouse', categoryLabel: 'Bakery & Cafe', tagline: 'Lahore Favorite', address: 'MM Alam Road, Gulberg III', city: 'Lahore', lat: 31.5204, lng: 74.3487, radius: 7, rating: 4.8, deliveryTime: '20-30 min', deliveryFee: pkr(100), hours: ['08:00', '23:00'], sections: ['Pastries', 'Bread', 'Coffee'], categories: ['bakery', 'food', 'coffee'], featured: true, note: 'Lahore only' },
  { id: 's_liberty_fresh', name: 'Liberty Fresh Mart', categoryLabel: 'Supermarket', address: 'Liberty Market, Gulberg', city: 'Lahore', lat: 31.512, lng: 74.345, radius: 8, rating: 4.5, deliveryTime: '25-35 min', deliveryFee: pkr(120), hours: ['09:00', '23:00'], sections: ['Fruit', 'Pantry', 'Household'], categories: ['grocery', 'household', 'essentials'], note: 'Lahore only' },
];

// ───────────────────────────── Products ─────────────────────────────

type SeedProduct = [
  id: string,
  storeId: string,
  name: string,
  price: number, // PKR
  section: string,
  description: string,
  extra?: { short?: string; unit?: string; daily?: boolean; unavailable?: boolean },
];

const PRODUCTS: SeedProduct[] = [
  // The Corner Bakery (ids match the app's mock data)
  ['p_almond_croissant', 's_corner_bakery', 'Almond Croissant', 425, 'Pastries', 'Twice-baked with house-made frangipane and topped with toasted almonds.'],
  ['p_cupcake', 's_corner_bakery', 'Fresh Strawberry Cupcake', 450, 'Pastries', 'Vanilla bean sponge folded with fresh strawberries, topped with real strawberry buttercream. Baked every morning.', { daily: true }],
  ['p_butter_croissant', 's_corner_bakery', 'Butter Croissant', 450, 'Pastries', 'Laminated by hand with cultured butter.', { short: 'Flaky & buttery' }],
  ['p_sourdough_loaf', 's_corner_bakery', 'Sourdough Loaf', 650, 'Bread', 'Slow-fermented for 24 hours using our 100-year-old starter.'],
  ['p_artisan_sourdough', 's_corner_bakery', 'Artisan Sourdough', 850, 'Bread', 'Our country loaf with a crackling crust.', { short: 'Whole loaf, sliced' }],
  ['p_sourdough', 's_corner_bakery', 'Handcrafted Sourdough', 650, 'Bread', 'Naturally leavened and baked on stone each morning.', { daily: true }],
  ['p_flat_white', 's_corner_bakery', 'Flat White', 450, 'Coffee', 'Double shot of espresso with silky micro-foam.'],
  ['p_club_sandwich', 's_corner_bakery', 'Chicken Club Sandwich', 950, 'Sandwiches', 'Grilled chicken, egg, lettuce and tomato on toasted sourdough.'],
  ['p_bun_kebab', 's_corner_bakery', 'Bun Kebab', 380, 'Sandwiches', 'Karachi classic with shami kebab, egg and chutney.', { unavailable: true }],
  // The Daily Grind
  ['p_cappuccino', 's_daily_grind', 'Cappuccino', 550, 'Coffee', 'Espresso with steamed milk and a deep layer of foam.'],
  ['p_iced_latte', 's_daily_grind', 'Iced Spanish Latte', 690, 'Coffee', 'Espresso, condensed milk and cold milk over ice.', { daily: true }],
  ['p_doodh_patti', 's_daily_grind', 'Doodh Patti Chai', 250, 'Tea', 'Strong tea brewed in milk, Karachi style.'],
  ['p_banana_bread', 's_daily_grind', 'Banana Bread Slice', 420, 'Snacks', 'Moist banana bread with walnuts.'],
  // Main St. Flowers
  ['p_tulips', 's_main_st_flowers', 'Seasonal Tulip Bouquet', 1200, 'Bouquets', 'A hand-tied bunch of the freshest seasonal tulips.', { daily: true }],
  ['p_roses', 's_main_st_flowers', 'Red Rose Dozen', 3500, 'Bouquets', 'Twelve long-stem red roses wrapped in kraft paper.'],
  ['p_money_plant', 's_main_st_flowers', 'Money Plant in Pot', 1800, 'Plants', 'Easy-care indoor plant in a ceramic pot.'],
  ['p_gift_hamper', 's_main_st_flowers', 'Chocolate Gift Hamper', 4800, 'Gifts', 'Assorted chocolates with a small bouquet.'],
  // Green Valley Organics
  ['p_bananas', 's_green_valley', 'Bananas', 220, 'Fruit', 'Sweet Sindhri bananas.', { unit: 'Dozen' }],
  ['p_mangoes', 's_green_valley', 'Chaunsa Mangoes', 600, 'Fruit', 'Seasonal Chaunsa mangoes.', { unit: 'KG', unavailable: true }],
  ['p_tomatoes', 's_green_valley', 'Organic Tomatoes', 280, 'Vegetables', 'Vine-ripened organic tomatoes.', { unit: 'KG' }],
  ['p_milk', 's_green_valley', 'Fresh Milk', 230, 'Dairy', 'Pasteurised full-cream milk.', { unit: '1 L' }],
  ['p_eggs', 's_green_valley', 'Desi Eggs', 540, 'Dairy', 'Free-range desi eggs.', { unit: 'Dozen', daily: true }],
  ['p_basmati', 's_green_valley', 'Basmati Rice', 1450, 'Pantry', 'Aged super kernel basmati.', { unit: '5 KG' }],
  // Night Owl Desserts
  ['p_choc_cake', 's_night_owl', 'Chocolate Fudge Cake', 2600, 'Cakes', 'Rich chocolate sponge with fudge frosting.', { unit: '1 lb' }],
  ['p_kulfi', 's_night_owl', 'Pista Kulfi', 350, 'Ice Cream', 'Traditional slow-cooked kulfi with pistachio.'],
  // Morning Bakes
  ['p_halwa_puri', 's_morning_bakes', 'Halwa Puri Platter', 650, 'Breakfast', 'Two puris, chana and suji halwa.'],
  ['p_paratha_roll', 's_morning_bakes', 'Egg Paratha Roll', 320, 'Breakfast', 'Flaky paratha rolled with spiced omelette.'],
  // Springfield Green Grocer
  ['p_strawberries', 's_springfield', 'Organic Strawberries', 400, 'Fruit', 'Sweet, locally grown and picked this morning.', { unit: 'KG', daily: true }],
  ['p_apples', 's_springfield', 'Kala Kulu Apples', 380, 'Fruit', 'Crisp apples from the north.', { unit: 'KG' }],
  ['p_spinach', 's_springfield', 'Fresh Spinach', 90, 'Vegetables', 'Washed and bundled palak.', { unit: 'Bunch' }],
  ['p_potatoes', 's_springfield', 'Potatoes', 120, 'Vegetables', 'All-purpose potatoes.', { unit: 'KG' }],
  // CarePlus Pharmacy
  ['p_panadol', 's_careplus', 'Paracetamol 500mg', 60, 'Medicines', 'Pain and fever relief. Strip of 10 tablets.', { short: 'Strip of 10' }],
  ['p_ors', 's_careplus', 'ORS Sachets', 150, 'Medicines', 'Oral rehydration salts, pack of 5.'],
  ['p_sanitizer', 's_careplus', 'Hand Sanitizer', 350, 'Personal Care', '70% alcohol hand sanitizer.', { unit: '250 ml' }],
  ['p_diapers', 's_careplus', 'Baby Diapers (Size 3)', 2450, 'Baby Care', 'Pack of 40 soft diapers.', { daily: true }],
  // Karachi Fresh Meats
  ['p_mutton', 's_karachi_meats', 'Mutton (Mixed Cuts)', 2400, 'Mutton', 'Fresh goat meat, mixed cuts.', { unit: 'KG' }],
  ['p_beef_mince', 's_karachi_meats', 'Beef Mince', 1300, 'Beef', 'Lean beef mince, freshly ground.', { unit: 'KG' }],
  ['p_chicken', 's_karachi_meats', 'Whole Chicken', 780, 'Chicken', 'Cleaned whole broiler chicken.', { unit: 'KG' }],
  ['p_prawns', 's_karachi_meats', 'Jumbo Prawns', 3200, 'Seafood', 'Cleaned jumbo prawns.', { unit: 'KG', unavailable: true }],
  // Byte Tech Hub
  ['p_usb_c_cable', 's_byte_tech', 'USB-C Cable 1m', 900, 'Accessories', 'Braided fast-charging cable.'],
  ['p_earbuds', 's_byte_tech', 'Wireless Earbuds', 6500, 'Audio', 'Bluetooth 5.3 earbuds with charging case.'],
  ['p_charger', 's_byte_tech', '20W Fast Charger', 2200, 'Chargers', 'USB-C PD wall charger.'],
  // Paws & Whiskers
  ['p_cat_food', 's_paws', 'Dry Cat Food', 2800, 'Food', 'Chicken recipe for adult cats.', { unit: '1.5 KG' }],
  ['p_dog_toy', 's_paws', 'Rope Chew Toy', 700, 'Toys', 'Durable cotton rope toy.'],
  ['p_grooming', 's_paws', 'Pet Grooming Session', 3500, 'Grooming', 'Bath, trim and nail clipping at home.'],
  // Nazimabad Hardware
  ['p_drill', 's_nazimabad_hardware', 'Cordless Drill', 12500, 'Tools', '12V cordless drill with two batteries.'],
  ['p_led_bulb', 's_nazimabad_hardware', 'LED Bulb 12W', 450, 'Electrical', 'Energy-saving cool white bulb.'],
  // Malir Farm Store
  ['p_farm_milk', 's_malir_farm', 'Farm Fresh Milk', 200, 'Dairy', 'Straight from the farm.', { unit: '1 L', daily: true }],
  ['p_farm_eggs', 's_malir_farm', 'Farm Eggs', 480, 'Eggs', 'Free-range eggs.', { unit: 'Dozen' }],
  // Old Town Grocers (inactive store)
  ['p_old_town_daal', 's_old_town', 'Masoor Daal', 420, 'Pantry', 'Split red lentils.', { unit: 'KG', daily: true }],
  // Lahore
  ['p_lhr_croissant', 's_gulberg_bakehouse', 'Lahori Butter Croissant', 480, 'Pastries', 'All-butter croissant.', { daily: true }],
  ['p_lhr_baguette', 's_gulberg_bakehouse', 'French Baguette', 400, 'Bread', 'Crusty baguette baked hourly.'],
  ['p_lhr_latte', 's_gulberg_bakehouse', 'Caramel Latte', 690, 'Coffee', 'Espresso, milk and caramel.'],
  ['p_lhr_oranges', 's_liberty_fresh', 'Kinnow Oranges', 350, 'Fruit', 'Juicy Sargodha kinnows.', { unit: 'Dozen', daily: true }],
  ['p_lhr_atta', 's_liberty_fresh', 'Chakki Atta', 1150, 'Pantry', 'Stone-ground whole-wheat flour.', { unit: '10 KG' }],
  ['p_lhr_detergent', 's_liberty_fresh', 'Laundry Detergent', 890, 'Household', 'Front-load safe detergent.', { unit: '1 KG' }],
];

// ───────────────────────────── People & places ─────────────────────────────

const PLACES = {
  clifton: { street: 'House 23, Street 4, Block 5, Clifton', city: 'Karachi', lat: 24.8138, lng: 67.03 },
  pechs: { street: 'Office 702, Shahrah-e-Faisal, PECHS', city: 'Karachi', lat: 24.864, lng: 67.075 },
  gulshan: { street: 'Flat B-12, Block 13-D, Gulshan-e-Iqbal', city: 'Karachi', lat: 24.92, lng: 67.095 },
  quetta: { street: 'Jinnah Road, Quetta Cantt', city: 'Quetta', lat: 30.1798, lng: 66.975 },
  gulberg: { street: 'House 11, Main Boulevard, Gulberg II', city: 'Lahore', lat: 31.516, lng: 74.343 },
};

const KARACHI_AREAS = [
  { street: 'Block 7, Clifton', lat: 24.822, lng: 67.033 },
  { street: 'Phase 2 Extension, DHA', lat: 24.835, lng: 67.06 },
  { street: 'Bahadurabad', lat: 24.881, lng: 67.067 },
  { street: 'PECHS Block 6', lat: 24.868, lng: 67.063 },
  { street: 'Saddar', lat: 24.857, lng: 67.02 },
  { street: 'Khayaban-e-Shamsheer, DHA Phase 5', lat: 24.806, lng: 67.047 },
];

const FIRST = ['Ayesha', 'Bilal', 'Fatima', 'Hamza', 'Hira', 'Usman', 'Sana', 'Ali', 'Zainab', 'Omar', 'Mahnoor', 'Saad', 'Iqra', 'Danish', 'Maryam'];
const LAST = ['Khan', 'Siddiqui', 'Ahmed', 'Qureshi', 'Malik', 'Raza', 'Shaikh', 'Hussain', 'Baig', 'Iqbal'];

async function main() {
  if (process.env.APP_ENV !== 'staging') {
    throw new Error(`Refusing to seed: APP_ENV is "${process.env.APP_ENV}". Seed data is for staging only.`);
  }
  const pool = new Pool({ connectionString: process.env.DATABASE_URL });
  const db = drizzle(pool, { schema });

  console.log('Clearing staging data…');
  await db.execute(sql`TRUNCATE TABLE
    order_events, order_items, orders, rides, payment_methods, addresses, refresh_tokens, verification_codes,
    products, store_categories, stores, categories, services, vehicle_types, users, app_settings
    RESTART IDENTITY CASCADE`);

  // Settings
  await db.insert(appSettings).values({
    id: 'global',
    searchRadiusKm: 10,
    defaultLatitude: 24.8607,
    defaultLongitude: 67.0011,
    defaultCityName: 'Karachi',
    freeDeliveryThreshold: pkr(1000),
    serviceFee: pkr(150),
    nearbyLimit: 10,
    supportPhone: '+92 21 111 000 000',
  });

  // Categories
  await db.insert(categories).values(
    CATEGORY_ROWS.map(([id, name, subtitle, icon, tint = 'red', featured = false], i) => ({
      id,
      name,
      subtitle,
      icon,
      tint,
      featured,
      sortOrder: i,
    })),
  );

  // Stores
  await db.insert(stores).values(
    STORES.map((s) => ({
      id: s.id,
      name: s.name,
      categoryLabel: s.categoryLabel,
      tagline: s.tagline ?? null,
      address: s.address,
      city: s.city,
      latitude: s.lat,
      longitude: s.lng,
      deliveryRadiusKm: s.radius,
      rating: s.rating,
      deliveryTime: s.deliveryTime,
      deliveryFee: s.deliveryFee,
      imageUrl: img(s.id),
      opensAt: s.hours?.[0] ?? null,
      closesAt: s.hours?.[1] ?? null,
      menuSections: s.sections,
      isFeatured: s.featured ?? false,
      isActive: s.active ?? true,
    })),
  );
  await db
    .insert(storeCategories)
    .values(STORES.flatMap((s) => s.categories.map((categoryId) => ({ storeId: s.id, categoryId }))));

  // Products
  await db.insert(products).values(
    PRODUCTS.map(([id, storeId, name, price, section, description, extra = {}], i) => ({
      id,
      storeId,
      name,
      price: pkr(price),
      section,
      description,
      shortDescription: extra.short ?? null,
      unit: extra.unit ?? null,
      imageUrl: img(id),
      isDailyPick: extra.daily ?? false,
      isAvailable: !extra.unavailable,
      sortOrder: i,
    })),
  );

  // Services & vehicles (ids/images match the app)
  await db.insert(services).values([
    { id: 'express_ride', name: 'Express Ride', image: 'express_ride', sortOrder: 0 },
    { id: 'delivery_package', name: 'Delivery Package', image: 'delivery_package', sortOrder: 1 },
    { id: 'moving', name: 'Home Moving', image: 'express_ride', sortOrder: 2 },
    { id: 'laundry_pickup', name: 'Laundry Pickup', image: 'delivery_package', sortOrder: 3, isActive: false },
  ]);
  await db.insert(vehicleTypes).values([
    { id: 'sedan', name: 'Sedan / Car', image: 'sedan', capacity: 'Up to 4 riders', baseFare: pkr(250), perKmFare: pkr(45), sortOrder: 0 },
    { id: 'van', name: 'Van / Shuttle', image: 'van', capacity: 'Up to 8 riders', baseFare: pkr(450), perKmFare: pkr(70), sortOrder: 1 },
    { id: 'truck', name: 'Utility Truck', image: 'truck', capacity: 'Up to 1 tonne', baseFare: pkr(1500), perKmFare: pkr(150), sortOrder: 2 },
    { id: 'bike', name: 'Motorbike', image: 'sedan', capacity: '1 rider', baseFare: pkr(120), perKmFare: pkr(20), sortOrder: 3, isActive: false },
  ]);

  // Users
  console.log('Creating users…');
  const customerHash = await bcrypt.hash('Password1', 10);
  const [admin] = await db
    .insert(users)
    .values([
      { firstName: 'Admin', lastName: 'KamKaj', email: 'admin@kamkaj.app', passwordHash: await bcrypt.hash('Admin@12345', 10), role: 'admin', emailVerified: true },
      { firstName: 'Sara', lastName: 'Support', email: 'staff@kamkaj.app', passwordHash: await bcrypt.hash('Staff@12345', 10), role: 'staff', emailVerified: true },
    ])
    .returning();
  void admin;

  const insertUser = async (email: string, firstName: string, lastName: string, extra: Partial<typeof users.$inferInsert> = {}) =>
    (
      await db
        .insert(users)
        .values({ email, firstName, lastName, passwordHash: customerHash, emailVerified: true, createdAt: ago(60), ...extra })
        .returning()
    )[0];

  const hello = await insertUser('hello@appname.com', 'Nouman', 'Gul', { phone: '+92 300 1234567', lastLoginAt: ago(0, 2) });
  const fresh = await insertUser('new@appname.com', 'Nadia', 'Newcomer', { createdAt: ago(0, 3) });
  const far = await insertUser('far@appname.com', 'Faisal', 'Quettawala');
  const lahori = await insertUser('lahore@appname.com', 'Laiba', 'Lahori');
  await insertUser('pending@appname.com', 'Pending', 'Person', { emailVerified: false, createdAt: ago(1) });
  await insertUser('blocked@appname.com', 'Blocked', 'Account', { status: 'blocked' });
  void fresh;

  // Addresses
  const [helloHome, helloWork] = await db
    .insert(addresses)
    .values([
      { userId: hello.id, type: 'home', label: 'My Home', ...place(PLACES.clifton), driverNotes: 'Ring the bell twice, gate on the left', isDefault: true },
      { userId: hello.id, type: 'work', label: 'My Office', ...place(PLACES.pechs), apartment: '7th floor' },
      { userId: hello.id, type: 'other', label: 'Parents', ...place(PLACES.gulshan) },
    ])
    .returning();
  await db.insert(addresses).values([
    { userId: far.id, type: 'home', label: 'My Home', ...place(PLACES.quetta), isDefault: true },
    { userId: lahori.id, type: 'home', label: 'My Home', ...place(PLACES.gulberg), isDefault: true },
  ]);

  // Payment methods
  const [visa, declined, cash] = await db
    .insert(paymentMethods)
    .values([
      { userId: hello.id, type: 'card', brand: 'Visa', last4: '4242', expiry: '12/29', isDefault: true },
      { userId: hello.id, type: 'card', brand: 'Mastercard', last4: '0002', expiry: '08/28' },
      { userId: hello.id, type: 'cash', brand: 'Cash on Delivery', last4: '', expiry: '' },
    ])
    .returning();
  await db.insert(paymentMethods).values([
    { userId: far.id, type: 'card', brand: 'Visa', last4: '1111', expiry: '01/30', isDefault: true },
    { userId: lahori.id, type: 'cash', brand: 'Cash on Delivery', isDefault: true },
  ]);

  // Orders for the demo user — every status
  console.log('Creating orders…');
  const priceOf = new Map(PRODUCTS.map((p) => [p[0], { name: p[2], price: pkr(p[3]) }]));
  const storeOf = new Map(STORES.map((s) => [s.id, s]));
  let number = 64900;

  async function makeOrder(o: {
    userId: string;
    storeId: string;
    address: { id: string; street: string; city: string; apartment: string | null; latitude: number | null; longitude: number | null };
    paymentMethodId: string | null;
    items: [string, number][];
    status: OrderStatus;
    createdAt: Date;
    statusNote?: string;
    courierName?: string;
    courierInfo?: string;
    cancelReason?: string;
  }) {
    const store = storeOf.get(o.storeId)!;
    const lines = o.items.map(([productId, quantity]) => {
      const p = priceOf.get(productId)!;
      return { productId, productName: p.name, unitPrice: p.price, quantity, lineTotal: p.price * quantity, note: null };
    });
    const subtotal = lines.reduce((s, l) => s + l.lineTotal, 0);
    const deliveryFee = subtotal >= pkr(1000) ? 0 : store.deliveryFee;
    const serviceFee = pkr(150);
    const minutes = Number(store.deliveryTime.match(/(\d+)\s*min/)?.[1] ?? 30);
    const [order] = await db
      .insert(orders)
      .values({
        number: number++,
        userId: o.userId,
        storeId: o.storeId,
        addressId: o.address.id,
        paymentMethodId: o.paymentMethodId,
        status: o.status,
        fromText: `${store.name}, ${store.address}`,
        toText: [o.address.apartment, o.address.street, o.address.city].filter(Boolean).join(', '),
        distanceKm:
          o.address.latitude != null
            ? Math.round(distanceKm({ lat: store.lat, lng: store.lng }, { lat: o.address.latitude, lng: o.address.longitude! }) * 10) / 10
            : null,
        subtotal,
        deliveryFee,
        serviceFee,
        total: subtotal + deliveryFee + serviceFee,
        statusNote: o.statusNote ?? null,
        courierName: o.courierName ?? null,
        courierInfo: o.courierInfo ?? null,
        cancelReason: o.cancelReason ?? null,
        estimatedAt: new Date(o.createdAt.getTime() + minutes * 60_000),
        paidAt: o.status === 'awaitingPayment' ? null : o.createdAt,
        deliveredAt: o.status === 'delivered' ? new Date(o.createdAt.getTime() + minutes * 60_000) : null,
        cancelledAt: o.status === 'cancelled' ? new Date(o.createdAt.getTime() + 10 * 60_000) : null,
        createdAt: o.createdAt,
        updatedAt: o.status === 'cancelled' ? new Date(o.createdAt.getTime() + 10 * 60_000) : o.createdAt,
      })
      .returning();
    await db.insert(orderItems).values(lines.map((l) => ({ ...l, orderId: order.id })));
    const history: { status: OrderStatus; note: string | null }[] = [
      { status: o.status === 'awaitingPayment' ? 'awaitingPayment' : 'pending', note: 'Order placed' },
    ];
    if (o.status === 'inTransit' || o.status === 'delivered') history.push({ status: 'inTransit', note: o.courierInfo ?? 'Rider picked up' });
    if (o.status === 'delivered') history.push({ status: 'delivered', note: null });
    if (o.status === 'cancelled') history.push({ status: 'cancelled', note: o.cancelReason ?? null });
    await db.insert(orderEvents).values(
      history.map((h, i) => ({
        orderId: order.id,
        status: h.status,
        note: h.note,
        actor: i === 0 ? 'customer' : 'admin:staff@kamkaj.app',
        createdAt: new Date(o.createdAt.getTime() + i * 15 * 60_000),
      })),
    );
    return order;
  }

  // Past (delivered) orders — oldest first so numbers increase over time
  const pastBaskets: [string, [string, number][]][] = [
    ['s_corner_bakery', [['p_sourdough_loaf', 1]]],
    ['s_daily_grind', [['p_cappuccino', 2], ['p_banana_bread', 1]]],
    ['s_green_valley', [['p_bananas', 1], ['p_milk', 2], ['p_eggs', 1]]],
    ['s_corner_bakery', [['p_almond_croissant', 2], ['p_flat_white', 2]]],
    ['s_main_st_flowers', [['p_tulips', 1]]],
    ['s_careplus', [['p_panadol', 2], ['p_sanitizer', 1]]],
    ['s_corner_bakery', [['p_cupcake', 4]]],
    ['s_daily_grind', [['p_iced_latte', 1]]],
    ['s_green_valley', [['p_basmati', 1], ['p_tomatoes', 2]]],
    ['s_corner_bakery', [['p_club_sandwich', 1], ['p_flat_white', 1]]],
    ['s_main_st_flowers', [['p_roses', 1]]],
    ['s_careplus', [['p_ors', 3]]],
  ];
  for (const [i, [storeId, items]] of pastBaskets.entries()) {
    await makeOrder({
      userId: hello.id,
      storeId,
      address: helloHome,
      paymentMethodId: i % 3 === 0 ? cash.id : visa.id,
      items,
      status: 'delivered',
      createdAt: ago(60 - i * 4, 3),
      courierName: 'Imran',
      courierInfo: 'Express Courier • Honda CD-70',
    });
  }
  // Old cancellation → shows under "past"
  await makeOrder({
    userId: hello.id, storeId: 's_daily_grind', address: helloHome, paymentMethodId: visa.id,
    items: [['p_doodh_patti', 2]], status: 'cancelled', createdAt: ago(20), cancelReason: 'Store was too busy to accept the order',
  });
  // Current orders
  await makeOrder({
    userId: hello.id, storeId: 's_corner_bakery', address: helloHome, paymentMethodId: declined.id,
    items: [['p_artisan_sourdough', 1], ['p_cupcake', 2]], status: 'awaitingPayment', createdAt: ago(0, 1),
    statusNote: 'Your card was declined. Tap Pay to try again.',
  });
  await makeOrder({
    userId: hello.id, storeId: 's_green_valley', address: helloHome, paymentMethodId: visa.id,
    items: [['p_eggs', 1], ['p_milk', 2], ['p_bananas', 1]], status: 'pending', createdAt: ago(0, 0.5),
  });
  await makeOrder({
    userId: hello.id, storeId: 's_main_st_flowers', address: helloWork, paymentMethodId: visa.id,
    items: [['p_gift_hamper', 1]], status: 'inTransit', createdAt: ago(0, 0.8),
    statusNote: 'Driver assigned • On schedule', courierName: 'Kashif', courierInfo: 'Express Courier • 1 parcel',
  });
  await makeOrder({
    userId: hello.id, storeId: 's_daily_grind', address: helloHome, paymentMethodId: cash.id,
    items: [['p_cappuccino', 1]], status: 'cancelled', createdAt: ago(1, 2), cancelReason: 'Cancelled by customer request',
  });

  // Extra customers so the admin panel has realistic lists and charts
  console.log('Creating extra customers…');
  const karachiStores = STORES.filter((s) => s.city === 'Karachi' && s.active !== false && PRODUCTS.some((p) => p[1] === s.id && !p[6]?.unavailable));
  for (let i = 0; i < 15; i++) {
    const firstName = FIRST[i % FIRST.length];
    const lastName = pick(LAST);
    const user = await insertUser(`${firstName.toLowerCase()}.${lastName.toLowerCase()}${i}@example.com`, firstName, lastName, {
      createdAt: ago(Math.floor(rand() * 30), 5),
    });
    const area = pick(KARACHI_AREAS);
    const [address] = await db
      .insert(addresses)
      .values({ userId: user.id, type: 'home', label: 'My Home', street: `House ${10 + i}, ${area.street}`, city: 'Karachi', latitude: area.lat, longitude: area.lng, isDefault: true })
      .returning();
    const [pm] = await db
      .insert(paymentMethods)
      .values({ userId: user.id, type: i % 2 ? 'card' : 'cash', brand: i % 2 ? 'Visa' : 'Cash on Delivery', last4: i % 2 ? String(1000 + i * 7) : '', expiry: i % 2 ? '10/28' : '', isDefault: true })
      .returning();
    const orderCount = 1 + Math.floor(rand() * 4);
    for (let n = 0; n < orderCount; n++) {
      const nearStores = karachiStores.filter((s) => distanceKm({ lat: s.lat, lng: s.lng }, { lat: area.lat, lng: area.lng }) <= s.radius);
      const store = pick(nearStores.length ? nearStores : karachiStores);
      const menu = PRODUCTS.filter((p) => p[1] === store.id && !p[6]?.unavailable);
      const items: [string, number][] = [[pick(menu)[0], 1 + Math.floor(rand() * 3)]];
      if (menu.length > 1 && rand() > 0.5) items.push([pick(menu)[0], 1]);
      const daysAgo = Math.floor(rand() * 14);
      const status: OrderStatus = daysAgo === 0 ? pick(['pending', 'inTransit', 'delivered'] as OrderStatus[]) : rand() > 0.12 ? 'delivered' : 'cancelled';
      await makeOrder({
        userId: user.id, storeId: store.id, address, paymentMethodId: pm.id, items, status,
        createdAt: ago(daysAgo, Math.floor(rand() * 10)),
        courierName: status === 'pending' ? undefined : 'Rider',
        courierInfo: status === 'inTransit' ? 'Express Courier • 1 parcel' : undefined,
        cancelReason: status === 'cancelled' ? pick(['Customer unreachable', 'Item out of stock', 'Cancelled by customer request']) : undefined,
      });
    }
    if (i < 4) {
      await db.insert(rides).values({
        userId: user.id,
        vehicleTypeId: pick(['sedan', 'van', 'truck']),
        status: pick(['requested', 'accepted', 'completed'] as const),
        pickupLat: area.lat,
        pickupLng: area.lng,
        createdAt: ago(i),
      });
    }
  }

  // Next real order continues after the seeded numbers.
  await db.execute(sql`SELECT setval('orders_number_seq', (SELECT GREATEST(MAX(number), 64999) FROM orders))`);

  const [{ n: orderTotal }] = (await db.execute(sql`select count(*)::int as n from orders`)).rows as { n: number }[];
  console.log(`Done: ${STORES.length} stores, ${PRODUCTS.length} products, ${CATEGORY_ROWS.length} categories, ${orderTotal} orders.`);
  console.log('Customer password: Password1 · verification code: 123456 · admin: admin@kamkaj.app / Admin@12345');
  await pool.end();
}

function place(p: { street: string; city: string; lat: number; lng: number }) {
  return { street: p.street, city: p.city, latitude: p.lat, longitude: p.lng };
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
