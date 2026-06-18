# Aikido Video Library Technical Specification

## 1. Purpose

The Aikido Video Library is a Rails web application for organizing, sharing, and watching Aikido instructional videos for a single dojo. Teachers create video entries that point to YouTube URLs and include rich text descriptions. Students are unauthenticated guests who can browse, search, sort, and watch all video entries in the library.

The application should prioritize a simple, durable domain model, clean sharing semantics, and a browsing experience that remains useful as the video library grows.

## 2. Technology Stack

- Ruby 4
- Rails 8
- SQLite
- TailwindCSS
- Hotwire/Turbo and Stimulus for progressive UI behavior
- Rails Action Text for rich text editing and rendering
- Rails authentication or an equivalent minimal teacher authentication system
- Minitest or RSpec, chosen before implementation and used consistently
- CSV gem for bulk video import/export under Ruby 4
- Docker dev container for local development

## 3. Product Decisions

- This is a single-dojo application, not a multi-tenant platform.
- Authenticated teachers can see and manage videos created by any teacher.
- All videos are visible on the public browse page, regardless of share status.
- Video sharing controls a direct public share URL only; it does not control whether the video appears in public browse results.
- Re-sharing a video or list filter should reuse its existing token when one exists.
- Initial saved list filters support text query and sorting.
- Students may sort shared list-filter results, but may not change the saved filter definition.
- Hard delete is acceptable for the MVP. Dependent share records can be destroyed with the video.
- Bulk CSV import and export are teacher-only capabilities. Students and guests cannot access CSV endpoints.
- CSV import is additive and idempotent by YouTube video ID: existing videos keep their existing title and URL, and imported keywords are merged into the video keyword set.
- CSV export uses the same `name,url,keywords` shape that import accepts, so exported files can be re-imported cleanly.

## 4. User Roles

### Guest Student

Students are unauthenticated users. They can:

- Browse all video entries in the library.
- Search video entries by title, keywords, and description text.
- Sort video entries.
- Open a watch page for any video entry.
- Play the video through an embedded YouTube player.
- View formatted video descriptions only on the watch page.
- View plain text descriptions everywhere outside the watch page.
- Open active shared list-filter URLs.

Students cannot create, update, delete, share, or unshare records.

### Authenticated Teacher

Teachers are authenticated users. They can:

- Create video entries.
- View all video entries created by all teachers.
- Update any video entry.
- Delete any video entry.
- Attach any number of keywords to a video entry.
- Share a video entry through a public URL.
- Stop sharing a video entry without deleting it.
- Create reusable list filters.
- Add rich text descriptions to shared list filters.
- Share or unshare list-filter URLs.
- Import video entries in bulk from CSV.
- Export the video library to CSV.

## 5. Domain Model

### Teacher

Represents an authenticated application user.

Suggested fields:

- `id`
- `email`
- `password_digest` or equivalent authentication credential fields
- `name`
- `created_at`
- `updated_at`

Associations:

- `has_many :videos`
- `has_many :video_shares`
- `has_many :video_list_filters`
- `has_many :video_list_filter_shares`

### Video

Represents a YouTube video entry in the dojo library.

Suggested fields:

- `id`
- `teacher_id`
- `title`
- `youtube_url`
- `youtube_video_id`
- `description_plain_text`
- `search_text`
- `position` optional, only if manual ordering is later required
- `published_at` optional, only if teachers need draft/published workflows
- `created_at`
- `updated_at`

Rich text:

- `has_rich_text :description`

Associations:

- `belongs_to :teacher`
- `has_many :video_keywords, dependent: :destroy`
- `has_many :keywords, through: :video_keywords`
- `has_one :video_share, dependent: :destroy`
- `has_one :active_video_share, -> { where(active: true) }, class_name: "VideoShare"`

Validation:

- `title` is required.
- `youtube_url` is required.
- `youtube_video_id` is required and derived from `youtube_url`.
- `teacher_id` is required.
- `title` should have a reasonable maximum length, for example 160 characters.
- `youtube_url` must be a supported YouTube watch, short, embed, or shorts URL.

Search:

- `description_plain_text` stores the plain text version of the rich text description.
- `search_text` stores normalized searchable text from title, keywords, and description.
- `search_text` should be rebuilt when title, keywords, or description changes.

Ownership:

- `teacher_id` records who created the video.
- `teacher_id` is not used to restrict teacher CRUD access in the MVP; all authenticated teachers can manage all videos.

### Keyword

Represents a reusable keyword.

Suggested fields:

- `id`
- `name`
- `normalized_name`
- `created_at`
- `updated_at`

Associations:

- `has_many :video_keywords`
- `has_many :videos, through: :video_keywords`

Validation:

- `name` is required.
- `normalized_name` is unique.

Notes:

- Normalize keyword names by trimming whitespace, collapsing repeated whitespace, and using case-insensitive matching.
- Display the original `name`; compare by `normalized_name`.

### VideoKeyword

Join model between videos and keywords.

Suggested fields:

- `id`
- `video_id`
- `keyword_id`
- `created_at`
- `updated_at`

Validation:

- Unique index on `[video_id, keyword_id]`.

### VideoShare

Represents a shareable URL for a single video entry.

Suggested fields:

- `id`
- `teacher_id`, the teacher who most recently shared or re-shared the video URL
- `video_id`
- `token`
- `active`
- `shared_at`
- `unshared_at`
- `created_at`
- `updated_at`

Associations:

- `belongs_to :teacher`
- `belongs_to :video`

Validation:

- `token` is required and unique.
- `active` is boolean and defaults to `true`.

Behavior:

- Sharing a video creates a `VideoShare` with a random token and `active: true` if no share record exists.
- Stopping sharing should set `active: false` and `unshared_at`, not destroy the record.
- A video should have at most one share record.
- Re-sharing should reactivate the existing share, reuse the existing token, set `active: true`, update `shared_at`, and clear `unshared_at`.
- If no prior share exists, sharing should create a new token.
- Unsharing disables only the direct share URL. It does not remove the video from public browse results.

### VideoListFilter

Represents a teacher-defined reusable browse/search filter.

Suggested fields:

- `id`
- `teacher_id`
- `name`
- `query`
- `sort_key`
- `sort_direction`
- `keyword_ids_snapshot` optional, if structured keyword filters are added later
- `filter_params`
- `description_plain_text`
- `created_at`
- `updated_at`

Rich text:

- `has_rich_text :description`

Associations:

- `belongs_to :teacher`
- `has_one :video_list_filter_share, dependent: :destroy`
- `has_one :active_video_list_filter_share, -> { where(active: true) }, class_name: "VideoListFilterShare"`

Validation:

- `name` is required.
- `sort_direction` must be `asc` or `desc`.
- `sort_key` must be one of the supported sort fields.

Notes:

- Store the reusable filter definition in structured form. For the initial app, `query`, `sort_key`, and `sort_direction` may be enough.
- `filter_params` can be a JSON text column in SQLite if future filter dimensions are expected.

### VideoListFilterShare

Represents a public URL for a teacher-defined list filter.

Suggested fields:

- `id`
- `teacher_id`, the teacher who most recently shared or re-shared the list-filter URL
- `video_list_filter_id`
- `token`
- `active`
- `shared_at`
- `unshared_at`
- `created_at`
- `updated_at`

Associations:

- `belongs_to :teacher`
- `belongs_to :video_list_filter`

Validation:

- `token` is required and unique.
- `active` is boolean and defaults to `true`.

Behavior:

- Sharing a list filter creates an active public token if no share record exists.
- Unsharing sets `active: false` and records `unshared_at`.
- A list filter should have at most one share record.
- Re-sharing should reactivate the existing share, reuse the existing token, set `active: true`, update `shared_at`, and clear `unshared_at`.
- If no prior share exists, sharing should create a new token.

## 6. Data Storage and Indexing

### Core Indexes

Add indexes for:

- `videos.teacher_id`
- `videos.youtube_video_id`
- `keywords.normalized_name`, unique
- `video_keywords.video_id`
- `video_keywords.keyword_id`
- `video_keywords.[video_id, keyword_id]`, unique
- `video_shares.token`, unique
- `video_shares.teacher_id`
- `video_shares.active`
- `video_shares.video_id`, unique
- `video_list_filters.teacher_id`
- `video_list_filter_shares.token`, unique
- `video_list_filter_shares.teacher_id`
- `video_list_filter_shares.active`
- `video_list_filter_shares.video_list_filter_id`, unique

### Search Strategy

The student browse view must filter by:

- Video title
- Keyword names
- Video description plain text

Recommended implementation:

1. Maintain `videos.description_plain_text`.
2. Maintain `videos.search_text` as normalized text containing:
   - title
   - all keyword names
   - description plain text
3. Query `search_text` with normalized terms.

For an MVP, use SQLite `LIKE` queries against `search_text`.

For a larger library, add SQLite FTS5 with an external-content table that indexes `videos.search_text`. This can be added without changing the public browsing contract.

### Rich Text Storage

Use Action Text for:

- Video descriptions.
- Shared list-filter descriptions.

Only the watch page should render rich text HTML. List pages, cards, previews, and teacher tables should use `description_plain_text`.

## 7. YouTube URL Handling

Create a dedicated parser object, for example `YoutubeVideoIdParser`, responsible for extracting and validating YouTube video IDs.

Supported URL formats:

- `https://www.youtube.com/watch?v=VIDEO_ID`
- `https://youtu.be/VIDEO_ID`
- `https://www.youtube.com/embed/VIDEO_ID`
- `https://www.youtube.com/shorts/VIDEO_ID`

Store:

- Original `youtube_url`
- Derived `youtube_video_id`

Embed format:

```text
https://www.youtube-nocookie.com/embed/:youtube_video_id
```

The embedded player should include a restrictive `allow` attribute and a clear title, for example `title="YouTube video player"`.

## 8. Routes

Suggested public routes:

```ruby
root "public/videos#index"

scope module: :public do
  resources :videos, only: [:index, :show]
  get "watch/:token", to: "video_shares#show", as: :public_video_share
  get "lists/:token", to: "video_list_filter_shares#show", as: :public_video_list
end
```

Suggested teacher routes:

```ruby
namespace :teacher do
  resources :videos do
    collection do
      post :import
      get :export
    end

    resource :share, only: [:create, :destroy], controller: "video_shares"
  end

  resources :video_list_filters do
    resource :share, only: [:create, :destroy], controller: "video_list_filter_shares"
  end
end
```

Authentication routes depend on the selected authentication implementation.

Route design notes:

- Direct share URL watch pages should resolve through active `VideoShare` records.
- Public video pages reached from browse should resolve through regular video IDs.
- Teacher CRUD routes should use regular video IDs.
- Public list-filter URLs should resolve through active `VideoListFilterShare` records.
- Inactive or unknown share tokens should return `404 Not Found`, not reveal record existence.

## 9. Controllers and Services

### Public Controllers

`Public::VideosController`

- `index`: Lists all videos with search and sorting.
- `show`: Renders the public watch page for any video in the library.

`Public::VideoSharesController`

- `show`: Resolves an active single-video share token and renders the same watch page used by `Public::VideosController#show`.

`Public::VideoListFilterSharesController`

- `show`: Resolves active list-filter share token, applies the saved filter, and renders the public list page with the list description.

### Teacher Controllers

`Teacher::VideosController`

- Full CRUD for all videos in the dojo library.
- Handles rich text description input.
- Handles keyword assignment through a form-friendly keyword input.

`Teacher::VideoSharesController`

- `create`: Shares a video by creating or reactivating its single share record.
- `destroy`: Unshares the active share for a video.
- Should reuse an existing token when reactivating a share.

`Teacher::VideoListFiltersController`

- Full CRUD for teacher-owned list filters.
- Allows rich text list description input.

`Teacher::VideoListFilterSharesController`

- `create`: Shares a teacher-owned list filter.
- `destroy`: Unshares the active share for a teacher-owned list filter.
- Should reuse an existing token when reactivating a share.

### Service Objects

Use small service objects for behavior that would otherwise clutter controllers or models:

- `YoutubeVideoIdParser`
- `Videos::KeywordAssigner`
- `Videos::SearchTextBuilder`
- `Videos::Query`
- `Videos::CsvImporter`
- `Videos::CsvExporter`
- `VideoShares::Create`
- `VideoShares::Deactivate`
- `VideoListFilterShares::Create`
- `VideoListFilterShares::Deactivate`

## 10. Browsing, Filtering, and Sorting

### Public Browse View

The public video list should support:

- Search input.
- Sort dropdown.
- Sort direction control.
- Pagination once the list grows.
- Empty state when no videos match.

Initial sort options:

- Newest
- Oldest
- Title A-Z
- Title Z-A
- Recently updated

Filtering behavior:

- Normalize the user's query by trimming whitespace and collapsing repeated spaces.
- Split multi-word searches into terms.
- Match all terms against `videos.search_text`.
- Search all videos in the library.
- Do not use share status as a public browse filter.

Suggested query object:

```ruby
Videos::Query.call(
  scope: Video.all,
  query: params[:q],
  sort: params[:sort],
  direction: params[:direction]
)
```

### Shared List Filters

A shared list-filter page should:

- Resolve `VideoListFilterShare` by token and `active: true`.
- Render the list-filter rich text description.
- Apply the saved filter parameters.
- List all videos matching the saved filter, regardless of video share status.
- Allow student sorting within the result set.
- Do not allow students to mutate the saved filter definition.

Recommended default:

- Shared list filters are stable, teacher-defined views.
- Students may sort within the shared filtered list.
- Students may not mutate the saved filter.


### Bulk CSV Import and Export

Bulk CSV import and export are available only to authenticated teachers through teacher video collection routes. These endpoints are not part of the public student surface.

Import rules:

- The header row must contain `name` and `url` columns, matched case-insensitively.
- `name` maps to `videos.title`.
- `url` maps to `videos.youtube_url` and is parsed through `YoutubeVideoIdParser`.
- Every other column is treated as a keyword source. Each cell is split on `;`, trimmed, squished, and empty values are dropped.
- A CSV exported by the app in `name,url,keywords` format must round-trip through import.
- Keywords are upserted case-insensitively through `Keyword.normalized_name`; existing canonical casing wins.
- Rows with a missing `name` or an unparseable YouTube URL are skipped and reported.
- Rows are matched by derived YouTube video ID. If a matching video already exists in the library or earlier in the same file, the existing video's keywords are replaced with the union of current and incoming keywords and the row is counted as merged. Existing title, URL, description, and creator attribution are left unchanged.
- Import returns `{ created, merged, skipped, errors: [{ row, name, reason }] }`.

Export rules:

- Export columns are `name,url,keywords`.
- `name` is the video title.
- `url` is the original stored YouTube URL.
- `keywords` is a `;`-joined alphabetical list of keyword display names.
- Standard CSV quoting is used, including for commas, quotes, and newlines.

## 11. Rich Text Requirements

### Supported Formatting

Video descriptions and list-filter descriptions must support:

- Bold
- Italic
- Heading 1
- Heading 2
- Heading 3
- Normal text
- Bullet lists
- Inline code
- Code blocks
- Horizontal rules

### Rendering Rules

Watch page:

- Render video description as sanitized rich text.
- Style rich text using Tailwind Typography or a constrained prose component.

List-filter shared page:

- Render the list description as sanitized rich text.

Everywhere else:

- Render description as plain text.
- Use truncation for cards and tables.

### Editor

Use Action Text with a customized toolbar or a small editor wrapper that exposes only the approved controls. If Trix does not provide an approved control cleanly, add a constrained Stimulus enhancement rather than allowing unsupported formatting.

## 12. Authorization

Use authentication checks for teacher actions:

- Teachers can manage all videos in the dojo library.
- Teachers can share and unshare any video in the dojo library.
- Teachers can only manage their own list filters.
- Teachers can only share and unshare their own list filters.

Public access checks:

- Single-video public URL requires `VideoShare.active = true`.
- List-filter public URL requires `VideoListFilterShare.active = true`.
- Public browse and public video pages are available for all videos.
- Public list-filter pages include all videos matching the saved filter, regardless of video share status.

Inactive share URLs should return `404 Not Found`, but the underlying video remains available through browse and its regular public video page.

## 13. UI Structure

### Public Student Views

Public index:

- Search and sort controls at the top.
- Results list with title, keywords, and plain text description preview.
- Clear indication when no results match.

Public watch page:

- Embedded YouTube player.
- Title.
- Keywords.
- Rich text description.

Shared list-filter page:

- List-filter title.
- Rich text list description.
- Filtered video list.

### Teacher Views

Teacher video index:

- Table or dense list of all videos in the dojo library.
- Teacher-only CSV import control.
- Teacher-only CSV export action.
- Share status.
- Actions for view, edit, delete, share, unshare.

Teacher video form:

- Title.
- YouTube URL.
- Keyword input.
- Rich text description.

Teacher list-filter index:

- Saved filters.
- Share status.
- Actions for view, edit, delete, share, unshare.

Teacher list-filter form:

- Name.
- Search query.
- Sort options.
- Rich text list description.

## 14. Security and Privacy

- Use secure random tokens for share URLs.
- Do not use sequential IDs in public share URLs.
- Enforce one share record per video and one share record per list filter with database constraints.
- Return `404` for inactive, missing, or unauthorized public share tokens.
- Sanitize rich text output through Rails' normal Action Text rendering pipeline.
- Validate YouTube URLs and embed only supported YouTube hosts.
- Use `youtube-nocookie.com` embed URLs by default.
- Add CSRF protection to teacher forms.
- Require authentication for all teacher namespace routes.
- Rate limiting can be added later for public search if abuse becomes a concern.

## 15. Development Environment

Use a Docker dev container so contributors develop against a consistent Ruby, Rails, SQLite, Node, and system package environment.

Recommended files:

- `.devcontainer/devcontainer.json`
- `.devcontainer/Dockerfile`
- `docker-compose.yml` if separate services or persistent named volumes are useful

The dev container should provide:

- Ruby 4 runtime.
- Rails 8-compatible system dependencies.
- SQLite development libraries and CLI.
- Node package tooling required by Rails 8 and TailwindCSS.
- Git and common shell utilities.
- A persistent bundle cache volume.
- A persistent node package cache volume if JavaScript package tooling is used.

The application should still run locally outside Docker for contributors who prefer a native setup, but the dev container is the documented default environment.

## 16. Suggested Database Schema Sketch

```ruby
create_table :teachers do |t|
  t.string :email, null: false
  t.string :password_digest, null: false
  t.string :name
  t.timestamps
end

add_index :teachers, :email, unique: true

create_table :videos do |t|
  t.references :teacher, null: false, foreign_key: true
  t.string :title, null: false
  t.string :youtube_url, null: false
  t.string :youtube_video_id, null: false
  t.text :description_plain_text
  t.text :search_text
  t.timestamps
end

create_table :keywords do |t|
  t.string :name, null: false
  t.string :normalized_name, null: false
  t.timestamps
end

add_index :keywords, :normalized_name, unique: true

create_table :video_keywords do |t|
  t.references :video, null: false, foreign_key: true
  t.references :keyword, null: false, foreign_key: true
  t.timestamps
end

add_index :video_keywords, [:video_id, :keyword_id], unique: true

create_table :video_shares do |t|
  t.references :teacher, null: false, foreign_key: true
  t.references :video, null: false, foreign_key: true
  t.string :token, null: false
  t.boolean :active, null: false, default: true
  t.datetime :shared_at
  t.datetime :unshared_at
  t.timestamps
end

add_index :video_shares, :token, unique: true
add_index :video_shares, :video_id, unique: true
add_index :video_shares, :active

create_table :video_list_filters do |t|
  t.references :teacher, null: false, foreign_key: true
  t.string :name, null: false
  t.string :query
  t.string :sort_key, null: false, default: "created_at"
  t.string :sort_direction, null: false, default: "desc"
  t.text :filter_params
  t.text :description_plain_text
  t.timestamps
end

create_table :video_list_filter_shares do |t|
  t.references :teacher, null: false, foreign_key: true
  t.references :video_list_filter, null: false, foreign_key: true
  t.string :token, null: false
  t.boolean :active, null: false, default: true
  t.datetime :shared_at
  t.datetime :unshared_at
  t.timestamps
end

add_index :video_list_filter_shares, :token, unique: true
add_index :video_list_filter_shares, :video_list_filter_id, unique: true
add_index :video_list_filter_shares, :active
```

Action Text will add its own tables.

## 17. Testing Strategy

### Model Tests

Cover:

- YouTube URL parsing.
- Video validation.
- Keyword normalization.
- Keyword assignment.
- Search text generation.
- Share token uniqueness.
- Active/inactive share behavior.
- Re-sharing reuses the existing token.
- List-filter validation.

### Query Tests

Cover:

- Search matches title.
- Search matches keywords.
- Search matches description plain text.
- Search includes videos regardless of share status.
- Sorting by supported sort options.
- Invalid sort params fall back to safe defaults.

### Request/System Tests

Cover:

- Guest can browse all videos.
- Guest can watch a video from the public browse page regardless of share status.
- Guest can watch through an active shared video URL.
- Inactive share URL returns 404.
- Teacher can create, update, delete video.
- Teacher can import videos from CSV.
- Teacher can export videos to CSV.
- Guest cannot access teacher CSV import or export endpoints.
- Teacher can update and delete videos created by other teachers.
- Teacher can share and unshare video.
- Teacher can create, share, and unshare list filter.
- Re-sharing a video or list filter reuses its existing token.
- Deleting a video destroys its dependent share record.
- Shared list filter renders all matching videos regardless of video share status.

### Rich Text Tests

Cover:

- Watch page renders formatted description.
- Index page renders plain text description.
- Unsupported tags or attributes are not persisted or rendered.

## 18. Implementation Milestones

### Milestone 1: Project Foundation

- Generate Rails app with SQLite and TailwindCSS.
- Add Docker dev container configuration.
- Configure authentication for teachers.
- Add Action Text.
- Add basic layout and navigation.

### Milestone 2: Video CRUD

- Add video model and creator attribution.
- Support dojo-wide teacher management of all videos.
- Add YouTube URL parsing.
- Add rich text video descriptions.
- Add keyword model and assignment.
- Add teacher video CRUD UI.

### Milestone 2.5: Bulk Video Import and Export

- Add teacher-only CSV import and export endpoints under the teacher video collection.
- Import CSV files with required `name` and `url` headers, matched case-insensitively.
- Treat all other columns as keyword sources, splitting cells on `;`, trimming whitespace, and dropping empty values.
- Create new videos from `name` and `url`, deriving and validating the YouTube video ID.
- Match existing rows by YouTube video ID and merge keywords additively while leaving existing video fields unchanged.
- Upsert keywords case-insensitively while preserving existing canonical casing.
- Report import results as `{ created, merged, skipped, errors: [{ row, name, reason }] }`.
- Export `name,url,keywords`, with keywords alphabetized and joined by `;` using standard CSV quoting.
- Cover importer, exporter, and teacher-only route access with tests.

### Milestone 3: Sharing

- Add `VideoShare`.
- Add share and unshare actions.
- Add public watch page.
- Ensure inactive shares return 404.
- Ensure re-sharing reuses the existing token.

### Milestone 4: Public Browse

- Add public video index.
- Add search over title, keywords, and description plain text.
- Add sorting.
- Add plain text description previews.

### Milestone 5: Shared List Filters

- Add `VideoListFilter`.
- Add rich text list-filter descriptions.
- Add `VideoListFilterShare`.
- Add public shared list-filter page.

### Milestone 6: Hardening

- Add pagination.
- Add focused system tests.
- Review accessibility of forms, search controls, and embedded player.
- Review authorization boundaries.
- Add FTS5 if the library size or search quality requires it.

## 19. Deferred Product Decisions

- Whether list filters should remain creator-owned or become dojo-wide editable by all teachers.
- Whether saved list filters should later support structured keyword filters in addition to text query and sorting.
- Whether video URLs should use numeric IDs, slugs, or a non-secret public identifier.
- Whether hard delete should be replaced with soft delete if audit history becomes important.
