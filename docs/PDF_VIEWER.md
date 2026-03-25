# PDF Viewer

The PDF viewer is an opt-in EditorJS block tool that renders PDF documents inline using PDF.js. PDFs are served via Active Storage with short-lived signed URLs.

## Enabling

Add `pdf: {}` to your tools configuration:

```ruby
# config/initializers/panda_editor.rb
Panda::Editor.configure do |config|
  config.tools = config.tools.merge(pdf: {})
end
```

## How It Works

### Editor (Admin)

1. The PDF tool appears in the EditorJS toolbar block picker.
2. Clicking it shows an upload area restricted to `.pdf` files.
3. The file is uploaded via the existing panda-cms file upload endpoint.
4. After upload, the block stores the file's `signed_id`, name, size, and extension.
5. The editor shows a preview with the PDF filename and a replace button.

### Block Data Format

```json
{
  "type": "pdf",
  "data": {
    "file": {
      "url": "/rails/active_storage/blobs/redirect/.../document.pdf",
      "name": "document.pdf",
      "size": 102400,
      "extension": "pdf",
      "signed_id": "eyJfcmFpbHMiOns..."
    },
    "title": "document.pdf"
  }
}
```

### Public Page Rendering

1. The Ruby block renderer (`Panda::Editor::Blocks::Pdf`) outputs an HTML container with a `data-pdf-url-endpoint` attribute pointing to the signed URL endpoint.
2. The `pdf_viewer.js` script (loaded automatically) finds these containers.
3. For each, it fetches a fresh short-lived URL from `GET /panda/editor/pdf_url/:signed_id`.
4. PDF.js loads the PDF from the CDN/cloud URL and renders it to a canvas.
5. Page navigation controls (prev/next) allow browsing multi-page PDFs.

### URL Security

- The `signed_id` is a cryptographic token — it cannot be guessed or enumerated.
- The runtime URL endpoint returns a direct cloud storage URL (S3, GCS, etc.) that expires in 5 minutes.
- PDF.js renders to a `<canvas>` element — there is no native browser PDF viewer with download buttons.
- The PDF URL in the page source is an API endpoint, not the PDF itself.

## Architecture

| Component | File | Purpose |
|-----------|------|---------|
| EditorJS tool | `app/javascript/panda/editor/tools/pdf_tool.js` | Upload and preview in admin |
| Block renderer | `lib/panda/editor/blocks/pdf.rb` | EditorJS JSON to HTML |
| URL controller | `app/controllers/panda/editor/pdf_urls_controller.rb` | Runtime signed URL generation |
| Route config | `lib/panda/editor/engine/route_config.rb` | Auto-mounts `GET /panda/editor/pdf_url/:signed_id` |
| Public viewer | `public/panda/editor/pdf_viewer.js` | PDF.js initialization and canvas rendering |
| Viewer styles | `public/panda/editor/pdf_viewer.css` | Viewer container and controls |

## Requirements

- **Active Storage** must be configured in the host application.
- **PDF.js** is loaded from the cdnjs CDN at runtime (no bundling required). The host page's CSP must allow `script-src` from `cdnjs.cloudflare.com`.
- **CORS**: If using cloud storage (S3, GCS), the storage bucket should have CORS configured to allow requests from your domain. This is needed because PDF.js fetches the PDF directly from the cloud URL.

## Turbo Drive

The viewer supports Turbo Drive navigation via the `turbo:load` event listener. PDFs are re-initialized when navigating between pages.
