// @ts-check
import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';
import tailwindcss from '@tailwindcss/vite';
import mermaid from 'astro-mermaid';
import starlightLinksValidator from 'starlight-links-validator'
import starlightVersions from 'starlight-versions'
import starlightHeadingBadges from 'starlight-heading-badges'
import starlightUtils from '@lorenzo_lewis/starlight-utils'
import starlightPageActions from 'starlight-page-actions'


// https://astro.build/config
export default defineConfig({
	integrations: [
		starlight({
			title: 'CRUD API',
			social: [{ icon: 'github', label: 'GitHub', href: 'https://github.com/withastro/starlight' }],
			sidebar: [
				{
					label: 'Ecosystem',
					items: [
						{ slug: 'ecosystem', label: 'Overview' },
					],
				},
				{
					label: 'Specifications',
					items: [
						{
							label: 'Base Specification',
							items: [
								{ slug: 'base', label: 'Overview' },
								{ slug: 'base/terminology', label: 'Terminology' },
								{ slug: 'base/general', label: 'General rules' },
								{ slug: 'base/operation', label: 'Operation rules' },
							],
						},
						{
							label: 'Extensions',
							items: [
								{ slug: 'extensions', label: 'Overview' },
								{ slug: 'extensions/async', label: 'Asyncability' },
								{ slug: 'extensions/metadata', label: 'Metadata' },
								{ slug: 'extensions/relationships', label: 'Relationships' },
							],
						},
						{
							label: 'Protocols',
							items: [
								{ slug: 'protocols', label: 'Overview' },
								{ slug: 'protocols/http' },
								{ slug: 'protocols/mcp' },
							],
						},
					],
				},
			],
			plugins: [
				starlightUtils({
					multiSidebar: {
						switcherStyle: 'horizontalList',
					},
				}),
				starlightVersions({
					versions: [{ slug: '0.1' }],
				}),
				starlightHeadingBadges(),
				starlightLinksValidator(),
				starlightPageActions({
					actions: {
						markdown: true,
						claude: true,
						custom: {
							editOnGitHub: {
								label: 'Edit on GitHub',
								href: 'https://github.com/crud-org/specs',
							},
						},
					},
				}),
			],
			customCss: ['./src/styles/global.css'],
			components: {
				Head: './src/components/Head.astro',
			},
		}),
    mermaid({ theme: 'forest', autoTheme: true }),
	],
	vite: {
		plugins: [tailwindcss()],
		server: {
			allowedHosts: true,
		},
		ssr: {
			external: ['node:sqlite'],
		},
	},
});
