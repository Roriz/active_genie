import { defineConfig } from 'vitepress'

// https://vitepress.dev/reference/site-config
export default defineConfig({
  lang: 'en-US',
  title: "ActiveGenie",
  description: "The Lodash for GenAI: Real Value + Consistent + Model-Agnostic",

  themeConfig: {
    logo: '/logo.webp',
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
          { text: 'What is ActiveGenie?', link: '/introduction/what-is-active-genie' },
          { text: 'Installation', link: '/introduction/installation' },
          { text: 'Quickstart', link: '/introduction/quickstart' },
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
          { text: 'Observability', link: '/reference/observability' },
        ]
      },
    ],

    socialLinks: [
      { icon: 'github', link: 'https://github.com/Roriz/active_genie' },
    ],

    footer: {
      copyright: 'Copyright © 2025 - Radamés Roriz'
    },
  },

  vite: {
    resolve: {
      preserveSymlinks: true
    }
  }
})
