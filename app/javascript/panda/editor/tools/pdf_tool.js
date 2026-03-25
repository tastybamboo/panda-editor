/**
 * PdfTool - EditorJS Block Tool for embedding PDF documents
 *
 * Allows users to upload a PDF file via the existing file upload endpoint.
 * On the public page, PDFs are rendered inline using PDF.js with page navigation.
 */

const PDF_ICON = '<svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path><polyline points="14 2 14 8 20 8"></polyline><line x1="16" y1="13" x2="8" y2="13"></line><line x1="16" y1="17" x2="8" y2="17"></line><polyline points="10 9 9 9 8 9"></polyline></svg>'

export default class PdfTool {
  static get toolbox() {
    return {
      title: 'PDF',
      icon: PDF_ICON
    }
  }

  static get isReadOnlySupported() {
    return true
  }

  constructor({ data, config, api, readOnly }) {
    this.data = data || {}
    this.config = config || {}
    this.api = api
    this.readOnly = readOnly
    this.wrapper = null
  }

  render() {
    this.wrapper = document.createElement('div')
    this.wrapper.classList.add('pdf-tool')

    if (this.data.file && this.data.file.signed_id) {
      this._renderFilePreview()
    } else {
      this._renderUploadArea()
    }

    return this.wrapper
  }

  _renderUploadArea() {
    const area = document.createElement('div')
    area.classList.add('pdf-tool__upload')
    area.style.cssText = 'display: flex; align-items: center; gap: 12px; padding: 16px; border: 2px dashed #d1d5db; border-radius: 8px; cursor: pointer; transition: border-color 0.2s;'
    area.innerHTML = `
      <div style="flex-shrink: 0; width: 40px; height: 40px; background: #fee2e2; border-radius: 8px; display: flex; align-items: center; justify-content: center;">
        <span style="color: #dc2626; font-weight: 700; font-size: 12px;">PDF</span>
      </div>
      <div>
        <div style="font-weight: 500; font-size: 14px; color: #374151;">Click to upload a PDF</div>
        <div style="font-size: 12px; color: #9ca3af;">PDF files only</div>
      </div>
    `

    area.addEventListener('mouseenter', () => { area.style.borderColor = '#9ca3af' })
    area.addEventListener('mouseleave', () => { area.style.borderColor = '#d1d5db' })

    if (!this.readOnly) {
      area.addEventListener('click', () => this._selectFile())
    }

    this.wrapper.appendChild(area)
  }

  _renderFilePreview() {
    const file = this.data.file
    const name = this._escape(file.name || 'Document.pdf')
    const size = this._formatSize(file.size)

    this.wrapper.innerHTML = `
      <div class="pdf-tool__file" style="display: flex; align-items: center; gap: 12px; padding: 16px; background: #fef2f2; border: 1px solid #fecaca; border-radius: 8px;">
        <div style="flex-shrink: 0; width: 40px; height: 40px; background: #dc2626; border-radius: 8px; display: flex; align-items: center; justify-content: center;">
          <span style="color: white; font-weight: 700; font-size: 12px;">PDF</span>
        </div>
        <div style="flex: 1; min-width: 0;">
          <div style="font-weight: 500; font-size: 14px; color: #374151; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;">${name}</div>
          <div style="font-size: 12px; color: #6b7280;">${size}</div>
        </div>
        ${!this.readOnly ? '<button class="pdf-tool__replace" style="flex-shrink: 0; padding: 4px 12px; font-size: 12px; color: #6b7280; background: white; border: 1px solid #d1d5db; border-radius: 6px; cursor: pointer;">Replace</button>' : ''}
      </div>
    `

    if (!this.readOnly) {
      const replaceBtn = this.wrapper.querySelector('.pdf-tool__replace')
      if (replaceBtn) {
        replaceBtn.addEventListener('click', (e) => {
          e.stopPropagation()
          this._selectFile()
        })
      }
    }
  }

  _selectFile() {
    const input = document.createElement('input')
    input.type = 'file'
    input.accept = '.pdf,application/pdf'
    input.addEventListener('change', (e) => {
      if (e.target.files[0]) {
        this._uploadFile(e.target.files[0])
      }
    })
    input.click()
  }

  async _uploadFile(file) {
    if (!file || file.type !== 'application/pdf') {
      this.api.notifier.show({
        message: 'Please select a PDF file',
        style: 'error'
      })
      return
    }

    // Show uploading state
    this.wrapper.innerHTML = `
      <div style="display: flex; align-items: center; gap: 12px; padding: 16px; border: 1px solid #d1d5db; border-radius: 8px;">
        <div style="width: 16px; height: 16px; border: 2px solid #d1d5db; border-top-color: #3b82f6; border-radius: 50%; animation: pdf-tool-spin 0.6s linear infinite;"></div>
        <span style="font-size: 14px; color: #6b7280;">Uploading ${this._escape(file.name)}...</span>
      </div>
      <style>@keyframes pdf-tool-spin { to { transform: rotate(360deg); } }</style>
    `

    const formData = new FormData()
    formData.append(this.config.field || 'file', file)

    try {
      const headers = {}
      if (this.config.csrfToken) {
        headers['X-CSRF-Token'] = this.config.csrfToken
      }

      const response = await fetch(this.config.endpoint, {
        method: 'POST',
        body: formData,
        headers
      })

      const result = await response.json()

      if (result.success === 1 || result.success === true) {
        this.data = {
          file: {
            url: result.file.url,
            name: result.file.name,
            size: result.file.size,
            extension: result.file.extension || 'pdf',
            signed_id: result.file.signed_id
          },
          title: result.file.name
        }
        this._renderFilePreview()
      } else {
        throw new Error('Upload failed')
      }
    } catch (error) {
      console.error('[PdfTool] Upload failed:', error)
      this.api.notifier.show({
        message: 'PDF upload failed. Please try again.',
        style: 'error'
      })
      // Restore upload area
      this.wrapper.innerHTML = ''
      this._renderUploadArea()
    }
  }

  save() {
    return this.data
  }

  validate(savedData) {
    return !!(savedData.file && savedData.file.signed_id)
  }

  _escape(str) {
    const div = document.createElement('div')
    div.textContent = str
    return div.innerHTML
  }

  _formatSize(bytes) {
    if (!bytes || bytes === 0) return ''
    const units = ['B', 'KB', 'MB', 'GB']
    const exp = Math.min(Math.floor(Math.log(bytes) / Math.log(1024)), units.length - 1)
    const size = (bytes / Math.pow(1024, exp)).toFixed(1)
    return `${size} ${units[exp]}`
  }
}
