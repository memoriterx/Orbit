# Web Research Sources Preset

This file provides a ready-to-use `{{RESEARCH_SOURCES}}` fill value for the base `researcher` agent when working on a web business project that has an external presence (location listings, review platforms, social media).

Copy the relevant sections below into your project's `CLAUDE.md` or researcher agent invocation to inject the `{{RESEARCH_SOURCES}}` slot.

---

## `{{RESEARCH_SOURCES}}` — Web Business Presence (Template)

Replace all `<placeholder>` values with your project's actual values before use.

```
- [Business Location Listing]: <URL to your business page on a map/listing platform>
  Access method: direct URL fetch or headless browser if JavaScript-rendered
  Collect: business name, address, hours, rating summary, review list (text, author, date, rating, visit type)

- [Review Platform Listing]: <URL to reviews page on your review platform>
  Access method: direct URL or platform API if available
  Collect: review count, average rating, individual reviews (text, rating, date, author)

- [Social Media Profile]: <URL to business Instagram / Facebook / etc.>
  Access method: public profile URL (unauthenticated)
  Collect: post captions, image URLs, hashtags, engagement signals (likes/comments count)

- [Official Website / Blog]: <URL to business website or blog>
  Access method: direct URL fetch
  Collect: product names, descriptions, pricing, published blog posts

- [Competitor Reference]: <optional — URL to a similar business for comparison>
  Access method: direct URL fetch
  Collect: product range, pricing tier, design patterns, UX patterns
```

---

## Example: Local Brick-and-Mortar Business

The following is a **filled example** for a local specialty studio (e.g., a craft workshop or artisan shop). This is illustrative — replace every value with your actual business details.

```
- [Location Listing — Map Platform]: https://<map-platform>/place/<your-place-id>
  Access method: headless browser (JavaScript-rendered page)
  Collect: rating, review count, review text (author, date, rating, visit type), hours, address

- [Review Aggregator — Platform B]: https://<review-platform>/biz/<your-slug>
  Access method: direct fetch
  Collect: reviews (author, text, rating, date)

- [Instagram Profile]: https://www.instagram.com/<your_handle>/
  Access method: public profile fetch (unauthenticated)
  Collect: post captions, image URLs, product-related hashtags

- [Official Blog / Posts]: https://<your-domain>/blog
  Access method: direct fetch
  Collect: published articles, product announcements, event posts
```

---

## Scraping Guidelines for the Researcher Agent

These apply regardless of which sources are used:

1. **Read-only**: never POST, PUT, DELETE, or authenticate with stored credentials.
2. **Rate limiting**: pause at least 1-2 seconds between page fetches. Do not crawl bulk pages without leader approval.
3. **Robots.txt awareness**: note in the report if `robots.txt` disallows the path. Do not bypass.
4. **JavaScript-rendered pages**: if a plain HTTP fetch returns empty content, note that a headless browser (e.g., Puppeteer) is required and report the limitation to the leader for approval before proceeding.
5. **Data classification**: tag each collected item as `confirmed` (visually verified) or `needs confirmation` (parsed but not visually checked).
6. **No credential storage**: if a source requires login, report as "access blocked — login required" and stop.

---

## How to Use This Preset

1. Copy the template above into your project's researcher invocation or `CLAUDE.md`.
2. Replace `<placeholder>` values with your actual source URLs.
3. Pass the filled content as the `{{RESEARCH_SOURCES}}` value when dispatching the base `researcher` agent.

The researcher agent will use this list as its investigation scope and report findings back to the leader.
