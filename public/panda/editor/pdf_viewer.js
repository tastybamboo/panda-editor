(function () {
  if (window.__pandaPdfViewerInitialized) return
  window.__pandaPdfViewerInitialized = true

  var PDFJS_VERSION = '4.8.69'
  var PDFJS_CDN = 'https://cdnjs.cloudflare.com/ajax/libs/pdf.js/' + PDFJS_VERSION

  var pdfjsLibPromise = null

  function loadPdfJs() {
    if (pdfjsLibPromise) return pdfjsLibPromise
    pdfjsLibPromise = import(PDFJS_CDN + '/pdf.min.mjs').then(function (pdfjsLib) {
      pdfjsLib.GlobalWorkerOptions.workerSrc = PDFJS_CDN + '/pdf.worker.min.mjs'
      return pdfjsLib
    })
    return pdfjsLibPromise
  }

  function initViewer(container, pdfjsLib) {
    var endpoint = container.dataset.pdfUrlEndpoint
    if (!endpoint) return

    var canvasEl = container.querySelector('.panda-pdf-viewer__canvas')
    var pageInfo = container.querySelector('.panda-pdf-viewer__page-info')
    var prevBtn = container.querySelector('.panda-pdf-viewer__prev')
    var nextBtn = container.querySelector('.panda-pdf-viewer__next')
    var viewerContainer = container.querySelector('.panda-pdf-viewer__container')

    if (!canvasEl || !pageInfo) return

    var ctx = canvasEl.getContext('2d')
    var pdf = null
    var currentPage = 1
    var totalPages = 0
    var rendering = false

    function renderPage(pageNum) {
      if (rendering || !pdf) return
      rendering = true

      pdf.getPage(pageNum).then(function (page) {
        var containerWidth = viewerContainer.clientWidth
        var viewport = page.getViewport({ scale: 1 })
        var scale = containerWidth / viewport.width
        var scaledViewport = page.getViewport({ scale: scale })

        canvasEl.height = scaledViewport.height
        canvasEl.width = scaledViewport.width

        var renderContext = {
          canvasContext: ctx,
          viewport: scaledViewport
        }

        page.render(renderContext).promise.then(function () {
          rendering = false
          pageInfo.textContent = 'Page ' + pageNum + ' of ' + totalPages
          prevBtn.disabled = pageNum <= 1
          nextBtn.disabled = pageNum >= totalPages
        }).catch(function (err) {
          rendering = false
          console.error('[Panda PDF Viewer] Render error:', err)
        })
      }).catch(function (err) {
        rendering = false
        console.error('[Panda PDF Viewer] Page load error:', err)
      })
    }

    prevBtn.addEventListener('click', function () {
      if (currentPage > 1) {
        currentPage--
        renderPage(currentPage)
      }
    })

    nextBtn.addEventListener('click', function () {
      if (currentPage < totalPages) {
        currentPage++
        renderPage(currentPage)
      }
    })

    // Responsive resize
    if (window.ResizeObserver) {
      var resizeTimeout = null
      var observer = new ResizeObserver(function () {
        clearTimeout(resizeTimeout)
        resizeTimeout = setTimeout(function () {
          if (pdf) renderPage(currentPage)
        }, 200)
      })
      observer.observe(viewerContainer)
    }

    // Fetch runtime signed URL and load PDF
    pageInfo.textContent = 'Loading...'

    fetch(endpoint)
      .then(function (response) {
        if (!response.ok) throw new Error('Failed to get PDF URL')
        return response.json()
      })
      .then(function (data) {
        return pdfjsLib.getDocument(data.url).promise
      })
      .then(function (pdfDoc) {
        pdf = pdfDoc
        totalPages = pdf.numPages
        currentPage = 1
        renderPage(1)
      })
      .catch(function (err) {
        console.error('[Panda PDF Viewer] Load error:', err)
        pageInfo.textContent = 'Failed to load PDF'
        prevBtn.style.display = 'none'
        nextBtn.style.display = 'none'
      })
  }

  function init() {
    var containers = document.querySelectorAll('.panda-pdf-viewer:not([data-pdf-initialized])')
    if (containers.length === 0) return

    loadPdfJs().then(function (pdfjsLib) {
      containers.forEach(function (container) {
        container.setAttribute('data-pdf-initialized', 'true')
        initViewer(container, pdfjsLib)
      })
    }).catch(function (err) {
      console.error('[Panda PDF Viewer] Failed to load PDF.js:', err)
    })
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init)
  } else {
    init()
  }

  // Support Turbo Drive navigation
  document.addEventListener('turbo:load', init)
})()
