inputs = %w[
  CollectionSelectInput
  DateTimeInput
  FileInput
  GroupedCollectionSelectInput
  NumericInput
  PasswordInput
  RangeInput
  StringInput
  TextInput
]

inputs.each do |input_type|
  "SimpleForm::Inputs::#{input_type}".constantize.class_eval do
    alias_method :__input_html_classes, :input_html_classes
    define_method(:input_html_classes) do
      __input_html_classes.push('form-control')
    end
  end
end
