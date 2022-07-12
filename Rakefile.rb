exp_dir = Dir.pwd + '/exp'
data_dir = Dir.pwd + '/data'

only_public = !ENV['ONLY_PUBLIC'].nil?

file "paper/cchpp.pdf" => [
  "paper/cchpp.tex",
  "paper/table/preprocessing.tex",
  "paper/table/customization.tex",
  "paper/table/queries.tex",
  "paper/fig/lazy_rphast_et_vs_dfs.pdf",
  "paper/fig/knn.pdf",
  "paper/table/alt_stats.tex",
  "paper/table/turn_opts.tex",

  "paper/table/customization_ger.tex",
  "paper/table/repr_knn_overview.tex",
  "paper/fig/repr_knn_ball_size.pdf",
  "paper/fig/repr_knn_num_pois.pdf",
  "paper/fig/lazy_rphast_et_vs_dfs_ger.pdf",
  "paper/fig/knn_ger.pdf",
  "paper/table/turn_opts_ext.tex",
] do
  Dir.chdir "paper" do
    sh "latexmk -pdf cchpp.tex"
  end
end

task default: "paper/cchpp.pdf"

namespace "fig" do
  directory "paper/fig"

  file "paper/fig/lazy_rphast_et_vs_dfs.pdf" => FileList[
    "#{exp_dir}/lazy_rphast/*.json",
  ] + ["eval/lazy_rphast_et_vs_dfs.py", "paper/fig"] do
    sh "eval/lazy_rphast_et_vs_dfs.py"
  end

  file "paper/fig/lazy_rphast_et_vs_dfs_ger.pdf" => FileList[
    "#{exp_dir}/lazy_rphast/*.json",
  ] + ["eval/lazy_rphast_et_vs_dfs_ger.py", "paper/fig"] do
    sh "eval/lazy_rphast_et_vs_dfs_ger.py"
  end

  file "paper/fig/knn.pdf" => FileList[
    "#{exp_dir}/knn/num_pois/*.json",
  ] + ["eval/knn.py", "paper/fig"] do
    sh "eval/knn.py"
  end

  file "paper/fig/knn_ger.pdf" => FileList[
    "#{exp_dir}/knn/num_pois/*.json",
  ] + ["eval/knn_ger.py", "paper/fig"] do
    sh "eval/knn_ger.py"
  end

  file "paper/fig/repr_knn_ball_size.pdf" => FileList[
    "#{exp_dir}/knn/repr/ball_size/*.json",
  ] + ["eval/repr_knn_ball_size.py", "paper/fig"] do
    sh "eval/repr_knn_ball_size.py"
  end

  file "paper/fig/repr_knn_num_pois.pdf" => FileList[
    "#{exp_dir}/knn/repr/num_pois/*.json",
  ] + ["eval/repr_knn_num_pois.py", "paper/fig"] do
    sh "eval/repr_knn_num_pois.py"
  end
end

namespace "table" do
  directory "paper/table"

  file "paper/table/preprocessing.tex" => FileList[
    "#{exp_dir}/preprocessing/*.json",
    "#{exp_dir}/turns/preprocessing/*.json",
    "#{exp_dir}/partitioning/*.out",
  ] + ["eval/preprocessing.py", "paper/table"] do
    sh "eval/preprocessing.py"
  end

  file "paper/table/customization.tex" => FileList[
    "#{exp_dir}/customization/*.json",
  ] + ["eval/customization.py", "paper/table"] do
    sh "eval/customization.py"
  end

  file "paper/table/customization_ger.tex" => FileList[
    "#{exp_dir}/customization/*.json",
  ] + ["eval/customization_ger.py", "paper/table"] do
    sh "eval/customization_ger.py"
  end

  file "paper/table/queries.tex" => FileList[
    "#{exp_dir}/queries/*.json",
  ] + ["eval/queries.py", "paper/table"] do
    sh "eval/queries.py"
  end

  file "paper/table/turn_opts.tex" => FileList[
    "#{exp_dir}/turns/partitioning/*.out",
    "#{exp_dir}/turns/preprocessing/*.json",
    "#{exp_dir}/turns/customization/*.json",
    "#{exp_dir}/turns/queries/*.json",
  ] + ["eval/turn_opts.py", "paper/table"] do
    sh "eval/turn_opts.py"
  end

  file "paper/table/turn_opts_ext.tex" => FileList[
    "#{exp_dir}/turns/partitioning/*.out",
    "#{exp_dir}/turns/preprocessing/*.json",
    "#{exp_dir}/turns/customization/*.json",
    "#{exp_dir}/turns/queries/*.json",
  ] + ["eval/turn_opts_ext.py", "paper/table"] do
    sh "eval/turn_opts_ext.py"
  end

  file "paper/table/repr_knn_overview.tex" => FileList[
    "#{exp_dir}/knn/repr/**/*.json",
  ] + ["eval/repr_knn_overview.py", "paper/table"] do
    sh "eval/repr_knn_overview.py"
  end

  file "paper/table/alt_stats.tex" => FileList[
    "#{exp_dir}/alternatives/*.json",
  ] + ["eval/alt.py", "paper/table"] do
    sh "eval/alt.py"
  end
end

osm_ger_src = 'https://download.geofabrik.de/europe/germany-200101.osm.pbf'
osm_ger_src_file = "#{data_dir}/germany-200101.osm.pbf"
osm_ger = "#{data_dir}/osm_ger/"
osm_ger_exp = "#{data_dir}/osm_ger_exp/"

live_dir = "#{data_dir}/mapbox/live-speeds/2019-08-02-15:41/"
typical_glob = "#{data_dir}/mapbox/typical-speeds/**/**/*.csv"
typical_file = "#{data_dir}/mapbox/typical-tuesday-cleaned.csv"
live_travel_time = 'live_travel_time'

dimacs_eur = "#{data_dir}/europe/"
dimacs_eur_exp = "#{data_dir}/europe_exp/"
dimacs_eur_turns = "#{data_dir}/europe_turns/"
dimacs_eur_turns_exp = "#{data_dir}/europe_turns_exp/"

stuttgart = "#{data_dir}/stuttgart/"
stuttgart_exp = "#{data_dir}/stuttgart_exp/"
london = "#{data_dir}/london/"
london_exp = "#{data_dir}/london_exp/"
chicago = "#{data_dir}/chicago/"
chicago_exp = "#{data_dir}/chicago_exp/"

graphs = [dimacs_eur, osm_ger]
main_graphs = graphs + [stuttgart]

turn_graphs = [[dimacs_eur, dimacs_eur_exp], [dimacs_eur_turns, dimacs_eur_turns_exp], [osm_ger, osm_ger_exp], [stuttgart, stuttgart_exp], [london, london_exp], [chicago, chicago_exp]]

namespace "prep" do
  file osm_ger_src_file => data_dir do
    sh "wget -O #{osm_ger_src_file} #{osm_ger_src}"
  end

  directory osm_ger
  file osm_ger => ["code/osm_import/build/import_osm", osm_ger_src_file] do
    wd = Dir.pwd
    Dir.chdir osm_ger do
      if only_public
        sh "#{wd}/code/osm_import/build/import_osm #{osm_ger_src_file}"
      else
        sh "#{wd}/code/osm_import/build/import_osm #{osm_ger_src_file} #{Dir[live_dir + '*'].join(' ')} #{typical_file}"
      end
    end
    Dir.chdir "code/rust_road_router" do
      sh "cargo run --release --bin write_unit_files -- #{osm_ger} 1000 1"
    end
  end

  file "#{osm_ger}#{live_travel_time}" => osm_ger do
    Dir.chdir "code/rust_road_router" do
      sh "cargo run --release --bin import_mapbox_live -- #{osm_ger} #{live_dir} #{live_travel_time}"
    end
  end

  directory osm_ger_exp
  file osm_ger_exp => [osm_ger] do
    Dir.chdir "code/rust_road_router" do
      sh "cargo run --release --bin turn_expand_osm -- #{osm_ger} #{osm_ger_exp}"
      sh "cargo run --release --bin write_unit_files -- #{osm_ger_exp} 1000 1"
    end
  end

  directory dimacs_eur_exp
  file dimacs_eur_exp => [dimacs_eur] do
    Dir.chdir "code/rust_road_router" do
      sh "cargo run --release --bin turn_expand_100s_uturn -- #{dimacs_eur} #{dimacs_eur_exp}"
    end
  end

  (graphs + turn_graphs.flatten).each do |graph|
    directory graph
    directory graph + "queries/rank"
    directory graph + "queries/uniform"

    file graph + "queries/1h" => graph do
      Dir.chdir "code/rust_road_router" do
        sh "cargo run --release --bin generate_1h_queries -- #{graph} 1000000"
      end
    end

    file graph + "queries/rank" => graph do
      Dir.chdir "code/rust_road_router" do
        sh "cargo run --release --bin generate_rank_queries -- #{graph}"
      end
    end

    file graph + "queries/uniform" => graph do
      Dir.chdir "code/rust_road_router" do
        sh "cargo run --release --bin generate_rand_queries -- #{graph} 1000000"
      end
    end

    file graph + "cch_perm" => [graph, "code/rust_road_router/lib/InertialFlowCutter/build/console"] do
      Dir.chdir "code/rust_road_router" do
        sh "./flow_cutter_cch_order.sh #{graph} #{Etc.nprocessors}"
      end
    end

    directory graph + "travel_time_ch"
    file graph + "travel_time_ch" => ["code/compute_ch/build/compute_ch"] do
      sh("code/compute_ch/build/compute_ch #{graph}/first_out #{graph}/head #{graph}/travel_time " +
          "#{graph}/travel_time_ch/order " +
          "#{graph}/travel_time_ch/forward_first_out #{graph}/travel_time_ch/forward_head #{graph}/travel_time_ch/forward_weight " +
          "#{graph}/travel_time_ch/backward_first_out #{graph}/travel_time_ch/backward_head #{graph}/travel_time_ch/backward_weight")
    end
  end

  turn_graphs.each do |graph, graph_exp|
    file graph_exp + "cch_perm_cuts" => [graph_exp, "code/rust_road_router/lib/InertialFlowCutter/build/console"] do
      Dir.chdir "code/rust_road_router" do
        sh "./flow_cutter_cch_cut_order.sh #{graph} #{Etc.nprocessors}"
        sh "mv #{graph}cch_perm_cuts #{graph_exp}"
      end
    end

    file graph_exp + "cch_perm_cuts_reorder" => [graph_exp, "code/rust_road_router/lib/InertialFlowCutter/build/console"] do
      Dir.chdir "code/rust_road_router" do
        sh "./flow_cutter_cch_cut_reorder.sh #{graph} #{Etc.nprocessors}"
        sh "mv #{graph}cch_perm_cuts_reorder #{graph_exp}"
      end
    end
  end
end

namespace "exp" do
  desc "Run all experiments"
  task all: [:preprocessing, :customization, :partitioning, :queries]

  directory "#{exp_dir}/customization"
  directory "#{exp_dir}/preprocessing"
  directory "#{exp_dir}/partitioning"
  directory "#{exp_dir}/queries"
  directory "#{exp_dir}/baseline_queries"

  namespace "turns" do
    task all: [:customization, :queries, :partitioning, :preprocessing]

    directory "#{exp_dir}/turns/partitioning"
    directory "#{exp_dir}/turns/preprocessing"
    directory "#{exp_dir}/turns/customization"
    directory "#{exp_dir}/turns/queries"
    directory "#{exp_dir}/turns/baseline_queries"

    task partitioning: ["#{exp_dir}/turns/partitioning", "code/rust_road_router/lib/InertialFlowCutter/build/console"] + turn_graphs.flatten do
      hostname = `hostname`
      turn_graphs.each do |g, g_exp|
        10.times do
          Dir.chdir "code/rust_road_router" do
            filename = "#{exp_dir}/turns/partitioning/" + `date --iso-8601=seconds`.strip + '.out'
            sh "echo '#{g} #{hostname}' >> #{filename}"
            sh "./flow_cutter_cch_order.sh #{g} #{Etc.nprocessors} >> #{filename}"

            filename = "#{exp_dir}/turns/partitioning/" + `date --iso-8601=seconds`.strip + '.out'
            sh "echo '#{g_exp} cuts #{hostname}' >> #{filename}"
            sh "./flow_cutter_cch_cut_reorder.sh #{g} #{Etc.nprocessors} >> #{filename}"

            filename = "#{exp_dir}/turns/partitioning/" + `date --iso-8601=seconds`.strip + '.out'
            sh "echo '#{g_exp} #{hostname}' >> #{filename}"
            sh "./flow_cutter_cch_order.sh #{g_exp} #{Etc.nprocessors} >> #{filename}"
          end
        end
      end
    end

    task preprocessing: ["#{exp_dir}/turns/preprocessing"] + turn_graphs.map { |g, g_exp|  [g + 'cch_perm', g_exp + 'cch_perm', g_exp + 'cch_perm_cuts', g_exp + 'cch_perm_cuts_reorder'] }.flatten do
      Dir.chdir "code/rust_road_router" do
        turn_graphs.each do |g, g_exp|
            # non-turn baseline
          sh "cargo run --release --bin cch_preprocessing_by_features -- #{g} cch_perm > #{exp_dir}/turns/preprocessing/$(date --iso-8601=seconds).json"
          # slow order on expanded graph
          sh "cargo run --release --bin cch_preprocessing_by_features -- #{g_exp} cch_perm > #{exp_dir}/turns/preprocessing/$(date --iso-8601=seconds).json"
          # cut order
          sh "cargo run --release --bin cch_preprocessing_by_features -- #{g_exp} cch_perm_cuts > #{exp_dir}/turns/preprocessing/$(date --iso-8601=seconds).json"
          # remove inf
          sh "cargo run --release --features 'remove-inf' --bin cch_preprocessing_by_features -- #{g_exp} cch_perm_cuts > #{exp_dir}/turns/preprocessing/$(date --iso-8601=seconds).json"
          # directed hierarchies
          sh "cargo run --release --features 'directed' --bin cch_preprocessing_by_features -- #{g_exp} cch_perm_cuts > #{exp_dir}/turns/preprocessing/$(date --iso-8601=seconds).json"
          # reordered separators
          sh "cargo run --release --features 'directed' --bin cch_preprocessing_by_features -- #{g_exp} cch_perm_cuts_reorder > #{exp_dir}/turns/preprocessing/$(date --iso-8601=seconds).json"
        end
      end
    end

    task customization: ["#{exp_dir}/turns/customization"] + turn_graphs.map { |g, g_exp|  [g + 'cch_perm', g_exp + 'cch_perm', g_exp + 'cch_perm_cuts', g_exp + 'cch_perm_cuts_reorder'] }.flatten do
      Dir.chdir "code/rust_road_router" do
        turn_graphs.each do |g, g_exp|
          ["", "RAYON_NUM_THREADS=1 "].each do |pre|
            # non-turn baseline
            sh "#{pre}cargo run --release --no-default-features --features 'perfect-customization' --bin cch_customization_by_features -- #{g} cch_perm > #{exp_dir}/turns/customization/$(date --iso-8601=seconds).json"
            # slow order on expanded graph
            sh "#{pre}cargo run --release --no-default-features --features 'perfect-customization' --bin cch_customization_by_features -- #{g_exp} cch_perm > #{exp_dir}/turns/customization/$(date --iso-8601=seconds).json"
            # cut order
            sh "#{pre}cargo run --release --no-default-features --features 'perfect-customization' --bin cch_customization_by_features -- #{g_exp} cch_perm_cuts > #{exp_dir}/turns/customization/$(date --iso-8601=seconds).json"
            # remove inf
            sh "#{pre}cargo run --release --no-default-features --features 'remove-inf perfect-customization' --bin cch_customization_by_features -- #{g_exp} cch_perm_cuts > #{exp_dir}/turns/customization/$(date --iso-8601=seconds).json"
            # directed hierarchies
            sh "#{pre}cargo run --release --no-default-features --features 'directed perfect-customization' --bin cch_customization_by_features -- #{g_exp} cch_perm_cuts > #{exp_dir}/turns/customization/$(date --iso-8601=seconds).json"
            # reordered separators
            sh "#{pre}cargo run --release --no-default-features --features 'directed perfect-customization' --bin cch_customization_by_features -- #{g_exp} cch_perm_cuts_reorder > #{exp_dir}/turns/customization/$(date --iso-8601=seconds).json"
          end
        end
      end
    end

    task queries: ["#{exp_dir}/turns/queries"] + turn_graphs.map { |g, g_exp|  [g + 'cch_perm', g_exp + 'cch_perm', g_exp + 'cch_perm_cuts', g_exp + 'cch_perm_cuts_reorder'] }.flatten do
      Dir.chdir "code/rust_road_router" do
        turn_graphs.each do |g, g_exp|
          # non-turn baseline
          sh "cargo run --release --no-default-features --features 'cch-disable-par' --bin cch_rand_queries_by_features -- #{g} cch_perm > #{exp_dir}/turns/queries/$(date --iso-8601=seconds).json"
          sh "cargo run --release --no-default-features --features 'cch-disable-par perfect-customization' --bin cch_rand_queries_by_features -- #{g} cch_perm > #{exp_dir}/turns/queries/$(date --iso-8601=seconds).json"
          # slow order on expanded graph
          sh "cargo run --release --no-default-features --features 'cch-disable-par' --bin cch_rand_queries_by_features -- #{g_exp} cch_perm > #{exp_dir}/turns/queries/$(date --iso-8601=seconds).json"
          sh "cargo run --release --no-default-features --features 'cch-disable-par perfect-customization' --bin cch_rand_queries_by_features -- #{g_exp} cch_perm > #{exp_dir}/turns/queries/$(date --iso-8601=seconds).json"
          # cut order
          sh "cargo run --release --no-default-features --features 'cch-disable-par' --bin cch_rand_queries_by_features -- #{g_exp} cch_perm_cuts > #{exp_dir}/turns/queries/$(date --iso-8601=seconds).json"
          sh "cargo run --release --no-default-features --features 'cch-disable-par perfect-customization' --bin cch_rand_queries_by_features -- #{g_exp} cch_perm_cuts > #{exp_dir}/turns/queries/$(date --iso-8601=seconds).json"
          # remove inf
          sh "cargo run --release --no-default-features --features 'cch-disable-par remove-inf' --bin cch_rand_queries_by_features -- #{g_exp} cch_perm_cuts > #{exp_dir}/turns/queries/$(date --iso-8601=seconds).json"
          sh "cargo run --release --no-default-features --features 'cch-disable-par remove-inf perfect-customization' --bin cch_rand_queries_by_features -- #{g_exp} cch_perm_cuts > #{exp_dir}/turns/queries/$(date --iso-8601=seconds).json"
          # directed hierarchies
          sh "cargo run --release --no-default-features --features 'cch-disable-par directed' --bin cch_rand_queries_by_features -- #{g_exp} cch_perm_cuts > #{exp_dir}/turns/queries/$(date --iso-8601=seconds).json"
          sh "cargo run --release --no-default-features --features 'cch-disable-par directed perfect-customization' --bin cch_rand_queries_by_features -- #{g_exp} cch_perm_cuts > #{exp_dir}/turns/queries/$(date --iso-8601=seconds).json"
          # reordered separators
          sh "cargo run --release --no-default-features --features 'cch-disable-par directed' --bin cch_rand_queries_by_features -- #{g_exp} cch_perm_cuts_reorder > #{exp_dir}/turns/queries/$(date --iso-8601=seconds).json"
          sh "cargo run --release --no-default-features --features 'cch-disable-par directed perfect-customization' --bin cch_rand_queries_by_features -- #{g_exp} cch_perm_cuts_reorder > #{exp_dir}/turns/queries/$(date --iso-8601=seconds).json"
          # CCHPot
          sh "cargo run --release --features 'cch-disable-par' --bin cchpot_turns_with_pre_exp -- #{g} cch_perm #{g_exp} > #{exp_dir}/turns/queries/$(date --iso-8601=seconds).json"
        end
      end
    end

    task baseline_queries: ["#{exp_dir}/turns/baseline_queries", dimacs_eur_exp] do
      Dir.chdir "code/rust_road_router" do
        sh "cargo run --release --bin baseline_rand_queries -- #{dimacs_eur_exp} > #{exp_dir}/turns/baseline_queries/$(date --iso-8601=seconds).json"
      end
    end
  end

  namespace "kNN" do
    directory "#{exp_dir}/knn/num_pois"
    directory "#{exp_dir}/knn/repr/num_pois"
    directory "#{exp_dir}/knn/repr/ball_size"

    task num_pois: ["#{exp_dir}/knn/num_pois"] + graphs.map { |g|  g + 'cch_perm' } do
      Dir.chdir "code/rust_road_router" do
        graphs.each do |g|
          sh "cargo run --release --features cch-disable-par --bin cch_nearest_neighbors_from_entire_graph -- #{g} > #{exp_dir}/knn/num_pois/$(date --iso-8601=seconds).json"
        end
      end
    end

    namespace "repr" do
      task num_pois: ["#{exp_dir}/knn/repr/num_pois", dimacs_eur + 'cch_perm'] do
        Dir.chdir "code/rust_road_router" do
          sh "cargo run --release --features cch-disable-par --bin cch_nearest_neighbors_from_entire_graph -- #{dimacs_eur} > #{exp_dir}/knn/repr/num_pois/$(date --iso-8601=seconds).json"
        end
      end

      task ball_size: ["#{exp_dir}/knn/repr/ball_size", dimacs_eur + 'cch_perm'] do
        Dir.chdir "code/rust_road_router" do
          sh "cargo run --release --features cch-disable-par --bin cch_nearest_neighbors_from_varying_balls -- #{dimacs_eur} > #{exp_dir}/knn/repr/ball_size/$(date --iso-8601=seconds).json"
        end
      end
    end
  end

  namespace "lazy_rphast" do
    directory "#{exp_dir}/lazy_rphast"

    task ball_size: ["#{exp_dir}/lazy_rphast"] + graphs.map { |g|  g + 'cch_perm' } + graphs.map { |g|  g + 'travel_time_ch' } do
      Dir.chdir "code/rust_road_router" do
        graphs.each do |g|
          sh "cargo run --release --features cch-disable-par --bin lazy_rphast_inc_cch_vs_elim_tree -- #{g} > #{exp_dir}/lazy_rphast/$(date --iso-8601=seconds).json"
        end
      end
    end
  end

  namespace "alternatives" do
    directory "#{exp_dir}/alternatives"

    task penalty: ["#{exp_dir}/alternatives"] + main_graphs.map { |g|  g + 'cch_perm' } do
      Dir.chdir "code/rust_road_router" do
        main_graphs.each do |g|
          sh "cargo run --release --features cch-disable-par --bin cchpot_penalty_iterative -- #{g} > #{exp_dir}/alternatives/$(date --iso-8601=seconds).json"
        end
      end
    end
  end

  task partitioning: ["#{exp_dir}/partitioning", "code/rust_road_router/lib/InertialFlowCutter/build/console"] + main_graphs do
    main_graphs.each do |graph|
      10.times do
        Dir.chdir "code/rust_road_router" do
          filename = "#{exp_dir}/partitioning/" + `date --iso-8601=seconds`.strip + '.out'
          sh "echo '#{graph}' >> #{filename}"
          sh "./flow_cutter_cch_order.sh #{graph} #{Etc.nprocessors} >> #{filename}"
        end
      end
    end
  end

  task preprocessing: ["#{exp_dir}/preprocessing"] + main_graphs.map { |g|  g + 'cch_perm' } do
    Dir.chdir "code/rust_road_router" do
      main_graphs.each do |graph|
        100.times do
          sleep 1
          sh "RAYON_NUM_THREADS=#{num_threads} cargo run --release --bin cch_preprocessing -- #{graph} > #{exp_dir}/preprocessing/$(date --iso-8601=seconds).json"
        end
      end
    end
  end

  task customization: ["#{exp_dir}/customization"] + main_graphs.map { |g|  g + 'cch_perm' } do
    Dir.chdir "code/rust_road_router" do
      main_graphs.each do |graph|
        num_threads = 1
        while num_threads <= Etc.nprocessors
          sh "RAYON_NUM_THREADS=#{num_threads} cargo run --release --bin cch_customization_by_features -- #{graph} > #{exp_dir}/customization/$(date --iso-8601=seconds).json"
          num_threads *= 2
        end
      end
    end
  end

  task queries: ["#{exp_dir}/queries", osm_ger + live_travel_time] + main_graphs.map { |g|  g + 'cch_perm' } do
    Dir.chdir "code/rust_road_router" do
      main_graphs.each do |graph|
        ['travel_time', 'geo_distance'].each do |m|
          sh "cargo run --release --features 'cch-disable-par' --bin cch_rand_queries_with_unpacking -- #{graph} #{m} > #{exp_dir}/queries/$(date --iso-8601=seconds).json"
          sh "cargo run --release --no-default-features --features 'cch-disable-par' --bin cch_rand_queries_with_unpacking -- #{graph} #{m} > #{exp_dir}/queries/$(date --iso-8601=seconds).json"
        end
      end
      sh "cargo run --release --features 'cch-disable-par' --bin cch_rand_queries_with_unpacking -- #{osm_ger} #{live_travel_time} > #{exp_dir}/queries/$(date --iso-8601=seconds).json"
      sh "cargo run --release --no-default-features --features 'cch-disable-par' --bin cch_rand_queries_with_unpacking -- #{osm_ger} #{live_travel_time} > #{exp_dir}/queries/$(date --iso-8601=seconds).json"
    end
  end

  task baseline_queries: ["#{exp_dir}/baseline_queries", osm_ger + live_travel_time] + main_graphs.map { |g|  g + 'cch_perm' } do
    Dir.chdir "code/rust_road_router" do
      main_graphs.each do |graph|
        ['travel_time', 'geo_distance'].each do |m|
          sh "cargo run --release --bin baseline_rand_queries -- #{graph} #{m} > #{exp_dir}/baseline_queries/$(date --iso-8601=seconds).json"
        end
      end
      sh "cargo run --release --bin baseline_rand_queries -- #{osm_ger} #{live_travel_time} > #{exp_dir}/baseline_queries/$(date --iso-8601=seconds).json"
    end
  end
end

namespace 'build' do
  task :osm_import => "code/osm_import/build/import_osm"
  directory "code/osm_import/build"
  file "code/osm_import/build/import_osm" => ["code/osm_import/build", "code/osm_import/src/bin/import_osm.cpp"] do
    Dir.chdir "code/osm_import/build/" do
      sh "cmake -DCMAKE_BUILD_TYPE=Release .. && make"
    end
  end

  task :compute_ch => "code/compute_ch/build/compute_ch"
  directory "code/compute_ch/build"
  file "code/compute_ch/build/compute_ch" => ["code/compute_ch/build", "code/compute_ch/src/bin/compute_contraction_hierarchy_and_order.cpp"] do
    Dir.chdir "code/compute_ch/build/" do
      sh "cmake -DCMAKE_BUILD_TYPE=Release .. && make"
    end
  end

  task routingkit: "code/RoutingKit/bin"
  file "code/RoutingKit/bin" do
    Dir.chdir "code/RoutingKit/" do
      sh "./generate_make_file"
      sh "make"
    end
  end

  task :inertialflowcutter => "code/rust_road_router/lib/InertialFlowCutter/build/console"

  directory "code/rust_road_router/lib/InertialFlowCutter/build"
  desc "Building Flow Cutter Accelerated"
  file "code/rust_road_router/lib/InertialFlowCutter/build/console" => ["code/rust_road_router/lib/InertialFlowCutter/src/console.cpp", "code/rust_road_router/lib/InertialFlowCutter/build"] do
    Dir.chdir "code/rust_road_router/lib/InertialFlowCutter/build" do
      sh "cmake -DCMAKE_BUILD_TYPE=Release .. && make console"
    end
  end
end

