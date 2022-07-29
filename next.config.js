/** @type {import('next').NextConfig} */
const nextConfig = {
    webpack: (config) => {
        config.experiments = { ...config.experiments, ...{ topLevelAwait: true } };
        return config;
    },
    reactStrictMode: true,
    swcMinify: true,
    output: 'standalone',
}

module.exports = nextConfig
