import type { NextConfig } from 'next';

const nextConfig: NextConfig = {
  reactStrictMode: true,
  // Images come from the API's /uploads and placeholder hosts; plain <img> is used, so no domain list is needed.
};

export default nextConfig;
