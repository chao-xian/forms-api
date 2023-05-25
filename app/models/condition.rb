class Condition < ApplicationRecord
  has_paper_trail

  belongs_to :routing_page, class_name: "Page"
  belongs_to :check_page, class_name: "Page", optional: true
  belongs_to :goto_page, class_name: "Page", optional: true

  has_one :form, through: :routing_page

  def save_and_update_form
    save && form.update!(question_section_completed: false)
  end

  def destroy_and_update_form!
    destroy! && form.update!(question_section_completed: false)
  end

  def validation_errors
    [
      warning_goto_page_doesnt_exist,
      warning_answer_doesnt_exist,
      warning_routing_to_next_page,
      warning_goto_page_before_check_page,
    ].compact
  end

  def warning_goto_page_doesnt_exist
    # goto_page_id isn't needed if the route is skipping to the end of the form
    return nil if goto_page_id.nil? && skip_to_end

    page = form.pages.find_by(id: goto_page_id)
    return nil if page.present?

    { name: "goto_page_doesnt_exist" }
  end

  def warning_answer_doesnt_exist
    answer_options = check_page&.answer_settings&.dig("selection_options")&.pluck("name")
    return nil if answer_options.blank? || answer_options.include?(answer_value)

    { name: "answer_value_doesnt_exist" }
  end

  def warning_routing_to_next_page
    return nil if check_page.nil? || goto_page.nil?

    check_page_position = check_page.position
    goto_page_position = goto_page.position

    return { name: "cannot_route_to_next_page" } if goto_page_position == (check_page_position + 1)

    nil
  end

  def warning_goto_page_before_check_page
    return nil if check_page.nil? || goto_page.nil?

    check_page_position = check_page.position
    goto_page_position = goto_page.position

    return { name: "cannot_have_goto_page_before_routing_page" } if goto_page_position < (check_page_position + 1)

    nil
  end

  def as_json(options = {})
    super(options.reverse_merge(
      except: [:next_page],
      methods: [:validation_errors],
    ))
  end
end
