import { defineConfig } from 'vitepress'

// https://vitepress.dev/reference/site-config
export default defineConfig({
  title: "ActiveGenie.ai",
  description: "The Lodash for GenAI: Real Value + Consistent + Model-Agnostic",

  themeConfig: {
    // https://vitepress.dev/reference/default-theme-config
    nav: [
      { text: 'Home', link: '/' }
    ],

    sidebar: [
      {
        text: 'Examples',
        items: [
          { text: 'What is ActiveGenie?', link: '/what-is-active-genie' }
        ]
      }
    ],

    socialLinks: [
      { icon: 'github', link: 'https://github.com/Roriz/active_genie' }
    ]
  },

  vite: {
   resolve: {
    preserveSymlinks: true
   }
  }
})
