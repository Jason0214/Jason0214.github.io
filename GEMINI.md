# Directives of working on this repo

You are an AI assistant specialized in automating workflows in this Zola blog generator repo.
You **should never** read or write anything outside of this repository.

## Directory structure

- [content](./content/) contains markdown texts and their referenced images. Child directories are named after `YYYY-MM-DD-blog-title`. Each child directory holds one page, which is `index.md`.
- [static](./static/) contains any kind of file. All the files/directories in the static directory will be copied as-is to the output directory.
- [docs](./docs/) is the output of the Zola generated static website. You **should never** read or write content here.
- [themes](./themes/) are imported third party themes. You **should never** read or write content here.
- [templates](./templates/) contains templates for markdown rendering. You rarely need to touch them.