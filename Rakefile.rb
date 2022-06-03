exp_dir = Dir.pwd + '/exp'
data_dir = Dir.pwd + '/data'

file "paper/cchpp.pdf" => [
  "paper/cchpp.tex",
] do
  Dir.chdir "paper" do
    sh "latexmk -pdf cchpp.tex"
  end
end

task default: "paper/cchpp.pdf"

namespace "fig" do
  directory "paper/fig"
end

namespace "table" do
  directory "paper/table"
end

osm_ger_src = 'https://download.geofabrik.de/europe/germany-200101.osm.pbf'
osm_ger_src_file = "#{data_dir}/germany-200101.osm.pbf"
osm_ger = "#{data_dir}/osm_ger/"
osm_ger_exp = "#{data_dir}/osm_ger_exp/"

live_dir = "#{data_dir}/mapbox/live-speeds/2019-08-02-15:41/"
typical_glob = "#{data_dir}/mapbox/typical-speeds/**/**/*.csv"
typical_file = "#{data_dir}/mapbox/typical-tuesday-cleaned.csv"

dimacs_eur = "#{data_dir}/europe/"
dimacs_eur_turns = "#{data_dir}/europe_turns/"
dimacs_eur_turns_exp = "#{data_dir}/europe_turns_exp/"

stuttgart = "#{data_dir}/stuttgart/"
stuttgart_exp = "#{data_dir}/stuttgart_exp/"

graphs = [dimacs_eur]

turn_graphs = [[dimacs_eur_turns, dimacs_eur_turns_exp], [osm_ger_exp, osm_ger], [stuttgart, stuttgart_exp]]

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

  directory osm_ger_exp
  file osm_ger_exp => [osm_ger] do
    Dir.chdir "code/rust_road_router" do
      sh "cargo run --release --bin turn_expand_osm -- #{osm_ger} #{osm_ger_exp}"
      sh "cargo run --release --bin write_unit_files -- #{osm_ger_exp} 1000 1"
    end
  end

  (graphs + turn_graphs.flatten).each do |graph|
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
  end

  turn_graphs.each do |_, graph|
    file graph + "cch_perm_cuts" => [graph, "code/rust_road_router/lib/InertialFlowCutter/build/console"] do
      Dir.chdir "code/rust_road_router" do
        sh "./flow_cutter_cch_cut_order.sh #{graph} #{Etc.nprocessors}"
      end
    end

    file graph + "cch_perm_cuts_reorder" => [graph, "code/rust_road_router/lib/InertialFlowCutter/build/console"] do
      Dir.chdir "code/rust_road_router" do
        sh "./flow_cutter_cch_cut_reorder.sh #{graph} #{Etc.nprocessors}"
      end
    end
  end
end

namespace "exp" do
  desc "Run all experiments"
  task all: [:preprocessing, :partitioning]

  directory "#{exp_dir}/preprocessing"
  directory "#{exp_dir}/partitioning"

  namespace "turns" do
    task all: [:customization, :queries]

    directory "#{exp_dir}/turns/customization"
    directory "#{exp_dir}/turns/queries"

    task customization: ["#{exp_dir}/turns/customization"] + turn_graphs.map { |g, g_exp|  [g + 'cch_perm', g_exp + 'cch_perm', g_exp + 'cch_perm_cuts', g_exp + 'cch_perm_cuts_reorder'] }.flatten do
      Dir.chdir "code/rust_road_router" do
        turn_graphs.each do |g, g_exp|
          # non-turn baseline
          sh "cargo run --release --no-default-features --features '' --bin cch_customization_by_features -- #{g} cch_perm > #{exp_dir}/turns/customization/$(date --iso-8601=seconds).json"
          sh "cargo run --release --no-default-features --features 'perfect-customization' --bin cch_customization_by_features -- #{g} cch_perm > #{exp_dir}/turns/customization/$(date --iso-8601=seconds).json"
          # slow order on expanded graph
          sh "cargo run --release --no-default-features --features '' --bin cch_customization_by_features -- #{g_exp} cch_perm > #{exp_dir}/turns/customization/$(date --iso-8601=seconds).json"
          sh "cargo run --release --no-default-features --features 'perfect-customization' --bin cch_customization_by_features -- #{g_exp} cch_perm > #{exp_dir}/turns/customization/$(date --iso-8601=seconds).json"
          # cut order
          sh "cargo run --release --no-default-features --features '' --bin cch_customization_by_features -- #{g_exp} cch_perm_cuts > #{exp_dir}/turns/customization/$(date --iso-8601=seconds).json"
          sh "cargo run --release --no-default-features --features 'perfect-customization' --bin cch_customization_by_features -- #{g_exp} cch_perm_cuts > #{exp_dir}/turns/customization/$(date --iso-8601=seconds).json"
          # remove inf
          sh "cargo run --release --no-default-features --features 'remove-inf' --bin cch_customization_by_features -- #{g_exp} cch_perm_cuts > #{exp_dir}/turns/customization/$(date --iso-8601=seconds).json"
          sh "cargo run --release --no-default-features --features 'remove-inf perfect-customization' --bin cch_customization_by_features -- #{g_exp} cch_perm_cuts > #{exp_dir}/turns/customization/$(date --iso-8601=seconds).json"
          # directed hierarchies
          sh "cargo run --release --no-default-features --features 'directed' --bin cch_customization_by_features -- #{g_exp} cch_perm_cuts > #{exp_dir}/turns/customization/$(date --iso-8601=seconds).json"
          sh "cargo run --release --no-default-features --features 'directed perfect-customization' --bin cch_customization_by_features -- #{g_exp} cch_perm_cuts > #{exp_dir}/turns/customization/$(date --iso-8601=seconds).json"
          # reordered separators
          sh "cargo run --release --no-default-features --features 'directed' --bin cch_customization_by_features -- #{g_exp} cch_perm_cuts_reorder > #{exp_dir}/turns/customization/$(date --iso-8601=seconds).json"
          sh "cargo run --release --no-default-features --features 'directed perfect-customization' --bin cch_customization_by_features -- #{g_exp} cch_perm_cuts_reorder > #{exp_dir}/turns/customization/$(date --iso-8601=seconds).json"
        end
      end
    end

    task queries: ["#{exp_dir}/turns/queries"] + turn_graphs.map { |g, g_exp|  [g + 'cch_perm', g_exp + 'cch_perm', g_exp + 'cch_perm_cuts', g_exp + 'cch_perm_cuts_reorder'] }.flatten do
      Dir.chdir "code/rust_road_router" do
        turn_graphs.each do |g, g_exp|
          # non-turn baseline
          sh "cargo run --release --no-default-features --features '' --bin cch_rand_queries_by_features -- #{g} cch_perm > #{exp_dir}/turns/queries/$(date --iso-8601=seconds).json"
          sh "cargo run --release --no-default-features --features 'perfect-customization' --bin cch_rand_queries_by_features -- #{g} cch_perm > #{exp_dir}/turns/queries/$(date --iso-8601=seconds).json"
          # slow order on expanded graph
          sh "cargo run --release --no-default-features --features '' --bin cch_rand_queries_by_features -- #{g_exp} cch_perm > #{exp_dir}/turns/queries/$(date --iso-8601=seconds).json"
          sh "cargo run --release --no-default-features --features 'perfect-customization' --bin cch_rand_queries_by_features -- #{g_exp} cch_perm > #{exp_dir}/turns/queries/$(date --iso-8601=seconds).json"
          # cut order
          sh "cargo run --release --no-default-features --features '' --bin cch_rand_queries_by_features -- #{g_exp} cch_perm_cuts > #{exp_dir}/turns/queries/$(date --iso-8601=seconds).json"
          sh "cargo run --release --no-default-features --features 'perfect-customization' --bin cch_rand_queries_by_features -- #{g_exp} cch_perm_cuts > #{exp_dir}/turns/queries/$(date --iso-8601=seconds).json"
          # remove inf
          sh "cargo run --release --no-default-features --features 'remove-inf' --bin cch_rand_queries_by_features -- #{g_exp} cch_perm_cuts > #{exp_dir}/turns/queries/$(date --iso-8601=seconds).json"
          sh "cargo run --release --no-default-features --features 'remove-inf perfect-customization' --bin cch_rand_queries_by_features -- #{g_exp} cch_perm_cuts > #{exp_dir}/turns/queries/$(date --iso-8601=seconds).json"
          # directed hierarchies
          sh "cargo run --release --no-default-features --features 'directed' --bin cch_rand_queries_by_features -- #{g_exp} cch_perm_cuts > #{exp_dir}/turns/queries/$(date --iso-8601=seconds).json"
          sh "cargo run --release --no-default-features --features 'directed perfect-customization' --bin cch_rand_queries_by_features -- #{g_exp} cch_perm_cuts > #{exp_dir}/turns/queries/$(date --iso-8601=seconds).json"
          # reordered separators
          sh "cargo run --release --no-default-features --features 'directed' --bin cch_rand_queries_by_features -- #{g_exp} cch_perm_cuts_reorder > #{exp_dir}/turns/queries/$(date --iso-8601=seconds).json"
          sh "cargo run --release --no-default-features --features 'directed perfect-customization' --bin cch_rand_queries_by_features -- #{g_exp} cch_perm_cuts_reorder > #{exp_dir}/turns/queries/$(date --iso-8601=seconds).json"
          # CCHPot
          sh "cargo run --release --bin cchpot_turns_with_pre_exp -- #{g} cch_perm #{g_exp} > #{exp_dir}/turns/queries/$(date --iso-8601=seconds).json"
        end
      end
    end
  end

  task preprocessing: ["#{exp_dir}/preprocessing"] + graphs.map { |g|  g + 'cch_perm' } do
    Dir.chdir "code/rust_road_router" do
      graphs.each do |graph|
        num_threads = 1
        while num_threads <= Etc.nprocessors
          100.times do
            sh "RAYON_NUM_THREADS=#{num_threads} cargo run --release --bin cch_preprocessing -- #{graph} > #{exp_dir}/preprocessing/$(date --iso-8601=seconds).json"
          end
          num_threads *= 2
        end
      end
    end
  end

  task partitioning: ["#{exp_dir}/partitioning", "code/rust_road_router/lib/InertialFlowCutter/build/console"] + graphs do
    graphs.each do |graph|
      10.times do
        Dir.chdir "code/rust_road_router" do
          filename = "#{exp_dir}/partitioning/" + `date --iso-8601=seconds`.strip + '.out'
          sh "echo '#{graph}' >> #{filename}"
          sh "./flow_cutter_cch_order.sh #{graph} #{Etc.nprocessors} >> #{filename}"
        end
      end
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
  file "code/rust_road_router/lib/InertialFlowCutter/build/console" => "code/rust_road_router/lib/InertialFlowCutter/build" do
    Dir.chdir "code/rust_road_router/lib/InertialFlowCutter/build" do
      sh "cmake -DCMAKE_BUILD_TYPE=Release .. && make console"
    end
  end
end

