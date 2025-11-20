import { defineConfig } from 'vitepress'

// https://vitepress.dev/reference/site-config
export default defineConfig({
  lang: 'en-US',
  title: "ActiveGenie",
  description: "The Lodash for GenAI: Consistent + Model-Agnostic",

  head: [
    ['script', { async: '', src: 'https://www.googletagmanager.com/gtag/js?id=G-R9WFVCSRP9' }],
    [
      'script',
      {},
      `window.dataLayer = window.dataLayer || [];
      function gtag(){dataLayer.push(arguments);}
      gtag('js', new Date());
      gtag('config', 'G-R9WFVCSRP9');`
    ]
  ],

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
          { text: 'Quickstart', link: '/introduction/quickstart' }
        ]
      },
      {
        text: 'Modules',
        items: [
          { text: 'Extractor', link: '/modules/extractor' },
          { text: 'Scorer', link: '/modules/scorer' },
          { text: 'Comparator', link: '/modules/comparator' },
          { text: 'Lister', link: '/modules/lister' },
          { text: 'Ranker', link: '/modules/ranker' },
        ]
      },
      {
        text: 'Benchmark',
        items: [
          { text: 'Latest', link: '/benchmark/latest' },
          { text: 'History', link: '/benchmark/history' },
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
      { icon: 'twitter', link: 'https://twitter.com/radamesroriz' },
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
