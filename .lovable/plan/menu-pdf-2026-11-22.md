# Menu PDF

## What will change
- Add a clear PDF/print button to the public menu, with Portuguese and English labels.
- Build a print-only version containing every active restaurant and beverage category and item, regardless of the current tab or search.
- Style the printable menu like a physical restaurant menu: elegant serif text, forest-green section bands, fine gold rules, dotted price leaders, and restaurant contact details.
- Add A4 print rules with category/item break protection, and set the public page's own title and description metadata.

## Technical details
- Use the browser print dialog so visitors can save the complete menu as a PDF without adding a PDF library.
- Keep existing database queries and menu data as the source; include active items, descriptions, prices, and sold-out labels in the selected language.
- Verify the print layout and button in desktop/mobile preview, then check the project build output.
