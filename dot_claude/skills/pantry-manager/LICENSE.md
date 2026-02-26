# Legal Terms and Conditions

## NYT Cooking Recipe Import

This tool can import recipes from NYT Cooking for **personal, non-commercial use only**.

### Important Legal Notices

- **NYT's Terms of Service** prohibit automated scraping without explicit permission
- You are using this tool **at your own discretion** for personal meal planning
- This tool is intended for **personal use only**
- **DO NOT** use this tool to build a commercial recipe database
- **DO NOT** distribute imported recipe data
- **DO NOT** republish or share scraped recipe content publicly

### Commercial Use

If you plan to:
- Make this tool publicly available
- Use it for commercial purposes
- Build a recipe database for distribution
- Integrate it into a commercial product

You **MUST obtain explicit written permission** from The New York Times Company first.

Contact: permissions@nytimes.com

## Rate Limiting and Respectful Access

To be respectful of external recipe sites:

- **Recipe imports are limited to one at a time**
- **2-second delay between requests** to avoid overwhelming servers
- **No batch imports** or automated scraping allowed
- **No concurrent requests** to the same domain

### Supported Sites

This tool can import from sites that provide Schema.org Recipe markup:

- **NYT Cooking** (https://cooking.nytimes.com) - Personal use only
- **Budget Bytes** (https://www.budgetbytes.com)
- Other sites with proper Schema.org markup

Each site may have its own terms of service. Please respect them.

## Data Storage

All imported data is stored locally at:
```
~/.local/share/pantry-manager/pantry.db
```

This SQLite database contains:
- Your personal pantry inventory
- Recipes you've imported for personal use
- Your favorites, ratings, and notes
- Ingredient relationships for meal planning

**This data should not be:**
- Redistributed or shared publicly
- Used to build a commercial database
- Sold or licensed to third parties
- Published or exported for public consumption

## Disclaimer

This software is provided "as is" without warranty of any kind. The authors and contributors:

- Make no representations about the accuracy of imported recipe data
- Are not responsible for any copyright violations that may occur through misuse
- Disclaim all liability for any legal issues arising from use of this tool
- Do not endorse or have affiliation with any recipe sites

## Your Responsibilities

By using this tool, you agree to:

1. **Use it only for personal, non-commercial purposes**
2. **Respect the terms of service** of all recipe sites
3. **Not redistribute or commercialize** imported recipe data
4. **Rate limit your requests** to be respectful of external servers
5. **Obtain permission** before any commercial or public use
6. **Take full responsibility** for your usage and any consequences

## Questions or Concerns

If you have questions about:
- Commercial licensing
- Permitted uses
- Terms of service compliance

Please consult with a legal professional before proceeding.

---

**Summary:** Use this tool responsibly for personal meal planning. Don't scrape aggressively, don't redistribute content, and don't commercialize it without permission.
