import { defineConfig } from 'vitepress'

// https://vitepress.dev/reference/site-config
export default defineConfig({
  lang: 'en-US',
  title: "ActiveGenie.ai",
  description: "The Lodash for GenAI: Real Value + Consistent + Model-Agnostic",

  themeConfig: {
    logo: '/assets/logo.webp',
    nav: [
      { text: 'Home', link: '/' },
      { text: 'Docs', link: '/introduction/installation' },
    ],

    search: {
      provider: 'local'
    },

    sidebar: [
      {
        text: 'Introduction',
        items: [
          { text: 'Installation', link: '/introduction/installation' },
          { text: 'Quick Start', link: '/introduction/quick-start' },
          { text: 'Basic Configuration', link: '/introduction/basic-configuration' },
        ]
      },
      {
        text: 'Modules',
        items: [
          { text: 'Data Extractor', link: '/modules/data_extractor' },
          { text: 'Scoring', link: '/modules/scoring' },
          { text: 'Battle', link: '/modules/battle' },
          { text: 'Ranking', link: '/modules/ranking' },
        ]
      },
      {
        text: 'Benchmark',
        items: [
          { text: 'Latest', link: '/benchmark/latest' },
        ]
      },
      {
        text: 'Reference',
        items: [
          { text: 'Configuration', link: '/reference/config' },
        ]
      },
    ],

    socialLinks: [
      { icon: 'github', link: 'https://github.com/Roriz/active_genie' },
    ],

    footer: {
      message: 'Released under the Apache License 2.0.',
      copyright: 'Copyright © 2025 - Radamés Roriz'
    },
  },

  vite: {
    resolve: {
      preserveSymlinks: true
    }
  }
})
