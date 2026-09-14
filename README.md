# PaperView

A lightweight, mountable dashboard for [paper_trail](https://github.com/paper-trail-gem/paper_trail).
Browse the `versions` table and read, in a chronological timeline, what actually changed.   

![preview](https://res.cloudinary.com/dlvuixik3/image/upload/v1789159753/paper_view_preview_aclugn.png)

## Installation

### 1. Add the gem

```ruby
# Gemfile
gem "paper_view"
```

### 2. Mount the engine

```ruby
# config/routes.rb
Rails.application.routes.draw do
  authenticate :user, ->(user) { user.admin? } do
    mount PaperView::Engine => "/versions"
  end
end
```

### 3. Configure it (optional)

```ruby
# config/initializers/paper_view.rb
PaperView.setup do |config|
  # Inherit from your own controller so that Devise/Pundit/layout helpers are available.
  config.parent_controller = "ApplicationController"

  # Runs as a before_action, evaluated inside the controller instance.
  config.authenticate_with { redirect_to main_app.root_path unless current_user&.admin? }

  # Must return a truthy value, otherwise the request is answered with 403.
  config.authorize_with { current_user.admin? }

  # Turn `whodunnit` into something readable.
  config.whodunnit_label = ->(whodunnit) { User.find_by(id: whodunnit)&.email || whodunnit }

  # Any strftime format.
  config.time_format = "%Y-%m-%d %H:%M:%S"

  config.per_page = 25

  # The exact columns to show as metadata. Defaults to every column that
  # paper_trail does not write itself, so usually nothing has to be set here.
  # config.metadata_columns = %w[ip user_agent]

  # Any model with the paper_trail column layout works here.
  # Required interface: id, item_type, item_id, event, whodunnit, created_at, object_changes
  config.version_class_name = "PaperTrail::Version"
end
```

Visit `/paper_view`.

## Metadata

paper_trail can store [extra columns](https://github.com/paper-trail-gem/paper_trail#4c-storing-metadata) on a
version, either through `has_paper_trail meta: { ... }` or through `controller_info`:

```ruby
class Post < ApplicationRecord
  has_paper_trail meta: {author_id: :author_id}
end
```

Every column of the `versions` table counts as metadata, except the ones paper_trail writes itself:
`id`, `item_type`, `item_subtype`, `item_id`, `event`, `whodunnit`, `object`, `object_changes`,
`created_at`, `updated_at` and `transaction_id`.

Set `config.metadata_columns` to the exact list you want if your table carries columns you would
rather not see — anything left out of that list is then hidden.

## PaperTrail setup

To work properly, PaperView requires an `object_changes` column in your `versions` table. This can be added by running the installation generator with the `--with-changes` option. This can be done even if you already have a `versions` table; it will generate a migration that adds the `object_changes` column to your existing `versions` table:

```bash
rails generate paper_trail:install --with-changes
```
