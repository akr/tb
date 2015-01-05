Gem::Specification.new do |s|
  s.name = 'tb'
  s.version = '1.0'
  s.date = '2014-10-29'
  s.author = 'Tanaka Akira'
  s.email = 'akr@fsij.org'
  s.required_ruby_version = '>= 1.9.2'
  s.add_development_dependency 'test-unit', '~> 2.5.5'
  s.files = %w[
    README
    bin/tb
    lib/tb.rb
    lib/tb/catreader.rb
    lib/tb/cmd_cat.rb
    lib/tb/cmd_consecutive.rb
    lib/tb/cmd_crop.rb
    lib/tb/cmd_cross.rb
    lib/tb/cmd_cut.rb
    lib/tb/cmd_git.rb
    lib/tb/cmd_group.rb
    lib/tb/cmd_gsub.rb
    lib/tb/cmd_help.rb
    lib/tb/cmd_join.rb
    lib/tb/cmd_ls.rb
    lib/tb/cmd_melt.rb
    lib/tb/cmd_mheader.rb
    lib/tb/cmd_nest.rb
    lib/tb/cmd_newfield.rb
    lib/tb/cmd_rename.rb
    lib/tb/cmd_search.rb
    lib/tb/cmd_shape.rb
    lib/tb/cmd_sort.rb
    lib/tb/cmd_svn.rb
    lib/tb/cmd_tar.rb
    lib/tb/cmd_to_csv.rb
    lib/tb/cmd_to_json.rb
    lib/tb/cmd_to_ltsv.rb
    lib/tb/cmd_to_pnm.rb
    lib/tb/cmd_to_pp.rb
    lib/tb/cmd_to_tsv.rb
    lib/tb/cmd_to_yaml.rb
    lib/tb/cmd_unmelt.rb
    lib/tb/cmd_unnest.rb
    lib/tb/cmdmain.rb
    lib/tb/cmdtop.rb
    lib/tb/cmdutil.rb
    lib/tb/csv.rb
    lib/tb/customcmp.rb
    lib/tb/customeq.rb
    lib/tb/enumerable.rb
    lib/tb/enumerator.rb
    lib/tb/ex_enumerable.rb
    lib/tb/ex_enumerator.rb
    lib/tb/fileenumerator.rb
    lib/tb/func.rb
    lib/tb/hashreader.rb
    lib/tb/hashwriter.rb
    lib/tb/headerreader.rb
    lib/tb/headerwriter.rb
    lib/tb/json.rb
    lib/tb/ltsv.rb
    lib/tb/ndjson.rb
    lib/tb/numericreader.rb
    lib/tb/numericwriter.rb
    lib/tb/pager.rb
    lib/tb/pnm.rb
    lib/tb/revcmp.rb
    lib/tb/ropen.rb
    lib/tb/search.rb
    lib/tb/tsv.rb
    lib/tb/zipper.rb
    sample/colors.ppm
    sample/excel2csv
    sample/gradation.pgm
    sample/langs.csv
    sample/poi-xls2csv.rb
    sample/poi-xls2csv.sh
    sample/tbplot
    tb.gemspec
    test-all-cov.rb
    test-all.rb
  ]
  s.test_files = %w[
    test/test_catreader.rb
    test/test_cmd_cat.rb
    test/test_cmd_consecutive.rb
    test/test_cmd_crop.rb
    test/test_cmd_cross.rb
    test/test_cmd_cut.rb
    test/test_cmd_git_log.rb
    test/test_cmd_grep.rb
    test/test_cmd_group.rb
    test/test_cmd_gsub.rb
    test/test_cmd_help.rb
    test/test_cmd_join.rb
    test/test_cmd_ls.rb
    test/test_cmd_melt.rb
    test/test_cmd_mheader.rb
    test/test_cmd_nest.rb
    test/test_cmd_newfield.rb
    test/test_cmd_rename.rb
    test/test_cmd_shape.rb
    test/test_cmd_sort.rb
    test/test_cmd_svn_log.rb
    test/test_cmd_tar_tvf.rb
    test/test_cmd_to_csv.rb
    test/test_cmd_to_json.rb
    test/test_cmd_to_ltsv.rb
    test/test_cmd_to_pnm.rb
    test/test_cmd_to_pp.rb
    test/test_cmd_to_tsv.rb
    test/test_cmd_to_yaml.rb
    test/test_cmd_unmelt.rb
    test/test_cmd_unnest.rb
    test/test_cmdtty.rb
    test/test_cmdutil.rb
    test/test_csv.rb
    test/test_customcmp.rb
    test/test_customeq.rb
    test/test_ex_enumerable.rb
    test/test_fileenumerator.rb
    test/test_headercsv.rb
    test/test_json.rb
    test/test_ltsv.rb
    test/test_ndjson.rb
    test/test_numericcsv.rb
    test/test_pager.rb
    test/test_pnm.rb
    test/test_reader.rb
    test/test_revcmp.rb
    test/test_search.rb
    test/test_tbenum.rb
    test/test_tsv.rb
    test/test_zipper.rb
    test/util_tbtest.rb
  ]
  s.has_rdoc = true
  s.homepage = 'https://github.com/akr/tb'
  s.require_path = 'lib'
  s.executables << 'tb'
  s.license = 'BSD-3-Clause'
  s.summary = 'manipulation tool for tables: CSV, TSV, LTSV, JSON, NDJSON, etc.'
  s.description = <<'End'
tb is a manipulation tool for tables.

tb provides a command and a library for manipulating tables:
Unix filter like operations (sort, cat, cut, ls, etc.),
SQL like operations (join, group, etc.),
other table operations (search, gsub, rename, cross, melt, unmelt, etc.),
information extractions (git, svn, tar),
and more.

tb supports various table formats: CSV, TSV, JSON, NDJSON, LTSV, etc.
End
end
