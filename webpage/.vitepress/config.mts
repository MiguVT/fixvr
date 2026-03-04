import { defineConfig } from 'vitepress'

// https://vitepress.dev/reference/site-config
export default defineConfig({
  srcDir: "docs",

  title: "FixVR",
  description: "Fix the Valve Index blank EDID bug on Linux - a tiny udev rule that stops your HMD from appearing as a 640×480 monitor.",

  themeConfig: {
    nav: [
      { text: 'Home', link: '/' },
      { text: 'Installation', link: '/install' },
    ],

    sidebar: [
      {
        text: 'Getting Started',
        items: [
          { text: 'Installation', link: '/install' },
        ]
      }
    ],

    socialLinks: [
      { icon: 'github', link: 'https://github.com/miguvt/fixvr' }
    ],

    footer: {
      message: 'Released under the MIT License.',
      copyright: 'Copyright © 2026-present FixVR contributors'
    }
  }
})
