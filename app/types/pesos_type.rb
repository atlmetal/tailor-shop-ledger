# Whole pesos from a money field: digits, or digits with the `$` and thousands separators that the
# field's formatting adds. Anything else, such as a decimal part, a sign or more pesos than an integer
# column holds, casts to nil. Validate these attributes with `comparison`, since `numericality` checks
# the raw `$50.000` and rejects it.
class PesosType < ActiveModel::Type::Integer
  FORMATTED = /\A\$?(?:\d+|\d{1,3}([.,])\d{3}(?:\1\d{3})*)\z/

  private
    def cast_value(value)
      return super unless value.is_a?(String)

      pesos = super(value.delete("$.,")) if value.match?(FORMATTED)
      pesos unless out_of_range?(pesos)
    end
end
