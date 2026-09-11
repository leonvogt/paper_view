# PaperView

A lightweight, mountable dashboard for [paper_trail](https://github.com/paper-trail-gem/paper_trail).
Browse the `versions` table, read a proper diff of `object_changes`, and roll a record back.

Runtime dependencies: `railties`, `activerecord`, `paper_trail`. Nothing else.

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
  mount PaperView::Engine => "/paper_view"
end
```

Mounting it inside an authenticated route is the simplest way to protect it:

```ruby
authenticate :user, ->(user) { user.admin? } do
  mount PaperView::Engine => "/paper_view"
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

  # Same, but only for the rollback action.
  config.authorize_revert_with { current_user.owner? }

  # Turn `whodunnit` into something readable.
  config.whodunnit_label = ->(whodunnit) { User.find_by(id: whodunnit)&.email || whodunnit }

  # Any strftime format.
  config.time_format = "%Y-%m-%d %H:%M:%S"

  config.per_page = 25
end
```

Visit `/paper_view`.
