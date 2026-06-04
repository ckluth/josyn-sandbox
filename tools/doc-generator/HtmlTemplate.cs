static class HtmlTemplate
{
    public static string Render(string title, string siteTitle, string cssPath, string navHtml, string contentHtml) =>
        $"""
        <!DOCTYPE html>
        <html lang="en">
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <title>{System.Net.WebUtility.HtmlEncode(title)} — {System.Net.WebUtility.HtmlEncode(siteTitle)}</title>
          <link rel="stylesheet" href="{cssPath}">
        </head>
        <body>
          <nav>
            <div class="nav-header">{System.Net.WebUtility.HtmlEncode(siteTitle)}</div>
            {navHtml}
          </nav>
          <main>
            <article>
              {contentHtml}
            </article>
          </main>
        </body>
        </html>
        """;

    public const string Css = """
        *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

        body {
          font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
          font-size: 16px;
          line-height: 1.75;
          color: #d4d4d4;
          background: #1e1e1e;
          display: flex;
          min-height: 100vh;
        }

        /* ── Sidebar ────────────────────────────────────────────────── */

        nav {
          width: 280px;
          flex-shrink: 0;
          background: #252526;
          color: #cccccc;
          font-size: 14px;
          position: fixed;
          top: 0; bottom: 0; left: 0;
          overflow-y: auto;
          border-right: 1px solid #3e3e42;
        }

        nav::-webkit-scrollbar { width: 6px; }
        nav::-webkit-scrollbar-track { background: transparent; }
        nav::-webkit-scrollbar-thumb { background: #424242; border-radius: 3px; }

        .nav-header {
          padding: 14px 16px 12px;
          font-size: 11px;
          font-weight: 700;
          letter-spacing: 0.1em;
          text-transform: uppercase;
          color: #bbbbbb;
          border-bottom: 1px solid #3e3e42;
          margin-bottom: 6px;
        }

        .nav-section {
          padding: 12px 16px 3px;
          font-size: 11px;
          font-weight: 700;
          letter-spacing: 0.08em;
          text-transform: uppercase;
          color: #6a9955;
        }

        a.nav-home {
          display: block;
          padding: 5px 16px;
          color: #cccccc;
          text-decoration: none;
          border-left: 2px solid transparent;
          white-space: nowrap;
          overflow: hidden;
          text-overflow: ellipsis;
        }

        a.nav-link {
          display: block;
          padding: 4px 16px 4px 28px;
          color: #cccccc;
          text-decoration: none;
          border-left: 2px solid transparent;
          white-space: nowrap;
          overflow: hidden;
          text-overflow: ellipsis;
        }

        a.nav-home:hover, a.nav-link:hover {
          background: #2a2d2e;
          color: #ffffff;
        }

        a.nav-home.active, a.nav-link.active {
          background: #094771;
          border-left-color: #007acc;
          color: #ffffff;
        }

        /* ── Content ────────────────────────────────────────────────── */

        main {
          margin-left: 280px;
          flex: 1;
          padding: 40px 56px;
          min-width: 0;
        }

        article {
          max-width: 860px;
        }

        h1, h2, h3, h4, h5, h6 {
          font-weight: 600;
          line-height: 1.3;
        }

        h1 {
          font-size: 1.8em;
          color: #569cd6;
          margin-top: 0;
          margin-bottom: 0.7em;
          padding-bottom: 0.4em;
          border-bottom: 1px solid #3e3e42;
        }

        h2 {
          font-size: 1.3em;
          color: #9cdcfe;
          margin-top: 2em;
          margin-bottom: 0.5em;
          padding-bottom: 0.3em;
          border-bottom: 1px solid #3e3e42;
        }

        h3 {
          font-size: 1.1em;
          color: #4ec9b0;
          margin-top: 1.6em;
          margin-bottom: 0.4em;
        }

        h4 {
          font-size: 1em;
          color: #dcdcaa;
          margin-top: 1.2em;
          margin-bottom: 0.3em;
        }

        p { margin: 0.7em 0; }

        a { color: #4fc1ff; text-decoration: none; }
        a:hover { color: #9cdcfe; text-decoration: underline; }

        code {
          font-family: "Cascadia Code", "Fira Code", Consolas, "Courier New", monospace;
          font-size: 0.875em;
          background: #2d2d2d;
          padding: 0.15em 0.45em;
          border-radius: 3px;
          color: #ce9178;
          border: 1px solid #3e3e42;
        }

        pre {
          background: #0d0d0d;
          border: 1px solid #3e3e42;
          padding: 1.1em 1.4em;
          border-radius: 4px;
          overflow-x: auto;
          line-height: 1.55;
          margin: 1.1em 0;
        }

        pre code {
          background: none;
          color: #d4d4d4;
          padding: 0;
          border: none;
          font-size: 0.875em;
        }

        blockquote {
          border-left: 3px solid #007acc;
          margin: 1.1em 0;
          padding: 0.5em 1.2em;
          background: #252526;
          color: #9e9e9e;
          border-radius: 0 3px 3px 0;
        }

        blockquote p { margin: 0.25em 0; }

        table {
          border-collapse: collapse;
          width: 100%;
          margin: 1.1em 0;
          font-size: 0.9em;
        }

        th {
          background: #2d2d2d;
          color: #9cdcfe;
          padding: 8px 14px;
          text-align: left;
          font-weight: 600;
          border-bottom: 2px solid #007acc;
          border-right: 1px solid #3e3e42;
        }

        th:last-child { border-right: none; }

        td {
          padding: 7px 14px;
          border-bottom: 1px solid #3e3e42;
          border-right: 1px solid #2d2d2d;
        }

        td:last-child { border-right: none; }

        tr:hover td { background: #2a2d2e; }

        ul, ol {
          padding-left: 1.6em;
          margin: 0.5em 0;
        }

        li { margin: 0.25em 0; }

        hr {
          border: none;
          border-top: 1px solid #3e3e42;
          margin: 2em 0;
        }

        strong { font-weight: 600; color: #e0e0e0; }

        em { color: #c0c0c0; }

        img { max-width: 100%; height: auto; }
        """;
}
