/** @type {import('next').NextConfig} */
const nextConfig = {
    trailingSlash: true,
    reactStrictMode: true,
    swcMinify: true,
    experimental: {
        images: {
            unoptimized: true,
        },
    },
}

module.exports = nextConfig
