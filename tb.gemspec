Gem::Specification.new do |s|
  s.name = 'tb'
  s.version = '0.1'
  s.date = '2011-12-01'
  s.author = 'Tanaka Akira'
  s.email = 'akr@fsij.org'
  s.files = %w[
    README
    bin/tb
    lib/tb.rb
    lib/tb/basic.rb
    lib/tb/csv.rb
    lib/tb/enumerable.rb
    lib/tb/fieldset.rb
    lib/tb/pathfinder.rb
    lib/tb/qtsv.rb
    lib/tb/reader.rb
    lib/tb/record.rb
    lib/tb/tsv.rb
    sample/excel2csv
    sample/poi-xls2csv.rb
    sample/poi-xls2csv.sh
    test-all.rb
  ]
  s.test_files = %w[
    test/test_basic.rb
    test/test_csv.rb
    test/test_enumerable.rb
    test/test_fieldset.rb
    test/test_record.rb
    test/test_tsv.rb
  ]
  s.has_rdoc = true
  s.homepage = 'https://github.com/akr/tb'
  s.require_path = 'lib'
  s.executables << 'tb'
  s.summary = 'manipulation tool for table: CSV, TSV, etc.'
  s.description = <<'End'
manipulation tool for table: CSV, TSV, etc.
End
end
