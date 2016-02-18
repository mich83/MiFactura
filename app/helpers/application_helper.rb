module ApplicationHelper

  def flash_class(level)
    case level
      when "notice" then "alert-info"
      when "success" then "alert-success"
      when "error" then "alert-danger"
      when "alert" then "alert-warning"
    end
  end

  # change the default link renderer for will_paginate
  def will_paginate(collection_or_options = nil, options = {})
    if collection_or_options.is_a? Hash
      options, collection_or_options = collection_or_options, nil
    end
    unless options[:renderer]
      options = options.merge :renderer => MyCustomLinkRenderer
    end
    super *[collection_or_options, options].compact
  end

  class MyCustomLinkRenderer < WillPaginate::ActionView::LinkRenderer
      def to_html
        html = pagination.map do |item|
          item.is_a?(Fixnum) ?
              page_number(item) :
              send(item)
        end.join(@options[:link_separator])

        Rails.logger.debug html_container(html).inspect
        @options[:container] ? html_container(html) : html

      end
    protected
      def html_container(html)
        tag(:ul, html, :class=>"pagination")
      end

      def previous_or_next_page(page, text, classname)
        if page
          tag(:li, link(text, page, :class => classname))
        else
          tag(:li, tag(:span, text),  :class => classname + ' disabled')
        end
      end

      def page_number(page)
        unless page == current_page
          tag(:li, link(page, page, :rel => rel_value(page)))
        else
          tag(:li, tag(:span, page),   :class => 'active')
        end
      end
      def gap
        text = @template.will_paginate_translate(:page_gap) { '&hellip;' }
        %(<li class='disabled'><span>#{text}</span></li>)
      end
  end
end
