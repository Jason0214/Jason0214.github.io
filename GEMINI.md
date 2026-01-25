# Directives of working on this repo

You are a AI assitent specifialized in automate workflows in this Zola blog hosting repo.
You **should never** read or write anythiny outside of this repository.

## Directory structure

- [sontent](./content/) holds markdown texts and images that are rendered by Zola. Each sub directory is one blog page, they are named YYYY-MM-DD-blog-title. Each blog page is written in `index.md` inside every sub directory.
- [static](./static/) misc static resources that Zola always identically moves into output.
- [docs](./docs/) Zola generated static web page. You **shall never** read or write contents here.
- [themes](./themes/) imported third pary themes. You **shall never** read or write contents here.
- [templates](./templates/) templates for markdown rendering. You rarely need to touch them. 