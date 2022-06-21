(() => {
    const shadowRoot = document.querySelector('custom-header').shadowRoot;
    const header = shadowRoot.getElementById('header');
    const link = document.createElement('link');

    link.setAttribute('rel', 'stylesheet');
    link.setAttribute('href', '/pexip-swift-sdk/assets/header.css');
    link.onload = () => {
      header.hidden = false;
    };
    shadowRoot.appendChild(link);
  })();