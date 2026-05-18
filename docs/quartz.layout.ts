import { PageLayout, SharedLayout } from "./quartz/cfg"
import * as Component from "./quartz/components"

export const sharedPageComponents: SharedLayout = {
  head: Component.Head(),
  header: [],
  afterBody: [],
  footer: Component.Footer({
    links: {},
  }),
}

/** Sort Explorer by numeric `order` in frontmatter, then folders, then name. */
function explorerSort(a: any, b: any): number {
  const ra =
    a.data && typeof a.data.order === "number" && Number.isFinite(a.data.order)
      ? a.data.order
      : a.isFolder
        ? 10000
        : 10001
  const rb =
    b.data && typeof b.data.order === "number" && Number.isFinite(b.data.order)
      ? b.data.order
      : b.isFolder
        ? 10000
        : 10001
  const d = ra - rb
  if (d !== 0) return d
  return a.displayName.localeCompare(b.displayName, undefined, {
    numeric: true,
    sensitivity: "base",
  })
}

const bookExplorerTitle = "Contents"

export const defaultContentPageLayout: PageLayout = {
  beforeBody: [
    Component.ConditionalRender({
      component: Component.Breadcrumbs(),
      condition: (page) => page.fileData.slug !== "index",
    }),
    Component.ArticleTitle(),
    Component.ContentMeta(),
  ],
  left: [
    Component.PageTitle(),
    Component.MobileOnly(Component.Spacer()),
    Component.Flex({
      components: [
        {
          Component: Component.Search(),
          grow: true,
        },
        { Component: Component.Darkmode() },
        { Component: Component.ReaderMode() },
      ],
    }),
    Component.Explorer({
      title: bookExplorerTitle,
      folderDefaultState: "open",
      useSavedState: true,
      sortFn: explorerSort,
    }),
  ],
  right: [
    Component.Graph(),
    Component.DesktopOnly(Component.TableOfContents()),
    Component.Backlinks(),
  ],
}

export const defaultListPageLayout: PageLayout = {
  beforeBody: [Component.Breadcrumbs(), Component.ArticleTitle(), Component.ContentMeta()],
  left: [
    Component.PageTitle(),
    Component.MobileOnly(Component.Spacer()),
    Component.Flex({
      components: [
        {
          Component: Component.Search(),
          grow: true,
        },
        { Component: Component.Darkmode() },
      ],
    }),
    Component.Explorer({
      title: bookExplorerTitle,
      folderDefaultState: "open",
      useSavedState: true,
      sortFn: explorerSort,
    }),
  ],
  right: [],
}
