# Provides support methods for string manipulation

class String
  # Converts dashes, underscores, and spaces to camelcase
  #
  # "foo_bar_baz".camelcase => "FooBarBaz"
  # "FooBarBaz".camelcase(false) => "fooBarBaz"
  def camelcase(first_letter_capitalized = true)
    # Convert separators
    camelcase = gsub(/[ _-]([^ _-])/) do |match|
      $1.upcase
    end
    
    # Convert first letter
    if first_letter_capitalized
      camelcase[0..0].upcase + camelcase[1..-1]
    else
      camelcase[0..0].downcase + camelcase[1..-1]
    end
  end

  # Removes module and class prefixes
  #
  # "Foo::Bar::Baz".demodulize => "Baz"
  def demodulize
    self[/([^:]+)$/]
  end

  # Converts dashes, spaces, and capitals to underscore separators.
  #
  # "FooBar-Baz Whee".underscore => 'foo_bar_baz_whee'
  def underscore(force_lower_case = true)
    # Convert separators
    underscore = gsub(/[ -]/, '_')

    # Convert capitals
    underscore.gsub!(/(.)([A-Z])/) do |match|
      $1 + '_' + $2
    end

    # Drop double underscores
    underscore.gsub!(/_+/, '_')

    if force_lower_case
      underscore.downcase
    else
      underscore
    end
  end
end
