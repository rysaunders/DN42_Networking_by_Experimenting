(function () {
  const lightTheme = {
    background: "#ffffff",
    primaryColor: "#eef2ff",
    primaryTextColor: "#111827",
    primaryBorderColor: "#4f46e5",
    lineColor: "#374151",
    secondaryColor: "#ecfeff",
    secondaryTextColor: "#111827",
    secondaryBorderColor: "#0f766e",
    tertiaryColor: "#f8fafc",
    tertiaryTextColor: "#111827",
    tertiaryBorderColor: "#64748b",
    clusterBkg: "#f8fafc",
    clusterBorder: "#64748b",
    edgeLabelBackground: "#ffffff",
    fontFamily: "Roboto, system-ui, sans-serif",
    noteBkgColor: "#fefce8",
    noteTextColor: "#111827",
    noteBorderColor: "#a16207",
  };

  const darkTheme = {
    background: "#1e2129",
    primaryColor: "#283348",
    primaryTextColor: "#f8fafc",
    primaryBorderColor: "#93c5fd",
    lineColor: "#cbd5e1",
    secondaryColor: "#123638",
    secondaryTextColor: "#f8fafc",
    secondaryBorderColor: "#5eead4",
    tertiaryColor: "#2b303b",
    tertiaryTextColor: "#f8fafc",
    tertiaryBorderColor: "#94a3b8",
    clusterBkg: "#242936",
    clusterBorder: "#94a3b8",
    edgeLabelBackground: "#1e2129",
    fontFamily: "Roboto, system-ui, sans-serif",
    noteBkgColor: "#422006",
    noteTextColor: "#fef3c7",
    noteBorderColor: "#f59e0b",
  };

  const getScheme = () => document.body.getAttribute("data-md-color-scheme");

  const getThemeVariables = () => {
    return getScheme() === "slate" ? darkTheme : lightTheme;
  };

  const configureMermaid = () => {
    if (!window.mermaid) {
      return;
    }

    window.mermaid.initialize({
      startOnLoad: false,
      theme: "base",
      securityLevel: "strict",
      themeVariables: getThemeVariables(),
    });
  };

  const restoreDiagramSource = (node) => {
    if (!node.dataset.mermaidSource) {
      node.dataset.mermaidSource = node.textContent;
    }

    node.removeAttribute("data-processed");
    node.textContent = node.dataset.mermaidSource;
  };

  const renderMermaid = () => {
    if (!window.mermaid) {
      return;
    }

    const diagrams = document.querySelectorAll(".mermaid");
    if (diagrams.length === 0) {
      return;
    }

    configureMermaid();
    diagrams.forEach(restoreDiagramSource);
    window.mermaid.run({ nodes: diagrams });
  };

  const debounce = (fn) => {
    let timeoutId;
    return () => {
      window.clearTimeout(timeoutId);
      timeoutId = window.setTimeout(fn, 50);
    };
  };

  const rerenderMermaid = debounce(renderMermaid);

  if (window.document$) {
    window.document$.subscribe(renderMermaid);
  } else {
    document.addEventListener("DOMContentLoaded", renderMermaid);
  }

  const observer = new MutationObserver((mutations) => {
    const colorSchemeChanged = mutations.some((mutation) => {
      return mutation.attributeName === "data-md-color-scheme";
    });

    if (colorSchemeChanged) {
      rerenderMermaid();
    }
  });

  observer.observe(document.body, {
    attributes: true,
    attributeFilter: ["data-md-color-scheme"],
  });
})();
