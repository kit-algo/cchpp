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

live_dir = "#{data_dir}/mapbox/live-speeds/2019-08-02-15:41/"
typical_glob = "#{data_dir}/mapbox/typical-speeds/**/**/*.csv"
typical_file = "#{data_dir}/mapbox/typical-tuesday-cleaned.csv"

dimacs_eur = "#{data_dir}/europe/"
graphs = [dimacs_eur]

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

  graphs.each do |graph|
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
end

namespace "exp" do
  desc "Run all experiments"
  task all: [:preprocessing, :partitioning]

  directory "#{exp_dir}/preprocessing"
  directory "#{exp_dir}/partitioning"

  task preprocessing: ["#{exp_dir}/preprocessing", "code/rust_road_router/lib/InertialFlowCutter/build/console"] + graphs.map { |g|  g + 'cch_perm' } do
    Dir.chdir "code/rust_road_router" do
      graphs.each do |graph|
        num_threads = 1
        while num_threads <= Etc.nprocessors
          100.times do
            sh "cargo run --release --bin cch_preprocessing -- #{graph} > #{exp_dir}/preprocessing/$(date --iso-8601=seconds).json"
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

