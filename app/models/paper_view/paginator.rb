module PaperView
  class Paginator
    WINDOW = 2
    PER_PAGE_OPTIONS = [25, 50, 100, 500].freeze

    attr_reader :page, :per_page, :total_count

    def initialize(relation, page:, per_page:)
      @relation = relation
      @per_page = per_page.to_i.clamp(1, 200)
      @total_count = relation.count(:all)
      @page = page.to_i.clamp(1, [total_pages, 1].max)
    end

    def per_page_options
      (PER_PAGE_OPTIONS + [per_page]).uniq.sort
    end

    def records
      @records ||= @relation.offset(offset).limit(per_page).to_a
    end

    def total_pages
      (total_count / per_page.to_f).ceil
    end

    def offset
      (page - 1) * per_page
    end

    def first_page?
      page <= 1
    end

    def last_page?
      page >= total_pages
    end

    def previous_page
      first_page? ? nil : page - 1
    end

    def next_page
      last_page? ? nil : page + 1
    end

    def page_numbers
      return [] if total_pages <= 1

      candidates = [1, total_pages]
      ((page - WINDOW)..(page + WINDOW)).each do |number|
        candidates << number if number.between?(1, total_pages)
      end

      candidates.uniq.sort.each_with_object([]) do |number, list|
        list << :gap if list.last.is_a?(Integer) && number > list.last + 1
        list << number
      end
    end
  end
end
