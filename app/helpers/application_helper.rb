module ApplicationHelper
  def sort_link(model, column, title = nil)
    # Uses helper methods from AdminsController.

    # If title is nil, make title from the column name
    title ||= column.titleize

    # Adds css classes "current" and "asd"/"desc", if column is currently being used to sort.
    # If the column is not being used to sort currently, add no classes.
    css_class = column == sort_column(model) ? "current #{sort_direction(model)}" : nil

    # If the direction is set to ascending, switch to descending. Default to ascending.
    # Only if the column is currently being used to sort.
    direction = column == sort_column(model) && sort_direction(model) == "asc" ? "desc" : "asc"

    # Return link logic to view, adds hash of parameters to the url, adds css classes
    case model
    when 'stat'
      link_to title, {:stat_sort => column, :stat_direction => direction}, {:class => css_class}
    when 'meeting'
      link_to title, {:meeting_sort => column, :meeting_direction => direction}, {:class => css_class}
    when 'user'
      link_to title, {:user_sort => column, :user_direction => direction}, {:class => css_class}
    when 'impression'
      link_to title, {:impression_sort => column, :impression_direction => direction}, {:class => css_class}
    end
  end
end
