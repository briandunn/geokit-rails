module Geokit
  module Adapters
    class SQLite < Abstract
      include Geokit::Mappable # for deg2rad

      # :lat: radians 
      # :lat: in radians
      def sphere_distance_sql(lat, lng, multiplier)
        %|
           cast( geokit_sphere_distance(#{lat.to_f},#{lng.to_f},#{qualified_lat_column_name},#{qualified_lng_column_name}, #{multiplier}) as numeric )
         |
      end

      def flat_distance_sql(origin, lat_degree_units, lng_degree_units)
        %|
          cast(geokit_flat_distance(#{origin.lat.to_f},#{origin.lng.to_f},#{qualified_lat_column_name},#{qualified_lng_column_name}, #{lat_degree_units}, #{lng_degree_units}) as numeric)
         |
      end

      def self.sphere_distance( origin_lat, origin_lng, lat, lng, multiplier )
        Math.acos( 
          [
            1.0,
            Math.cos(origin_lat) * Math.cos(origin_lng) * Math.cos(deg2rad(lat)) * Math.cos(deg2rad(lng)) + 
            Math.cos(origin_lat) * Math.sin(origin_lng) * Math.cos(deg2rad(lat)) * Math.sin(deg2rad(lng)) +
            Math.sin(origin_lat) * Math.sin(deg2rad(lat))
          ].min
        ) * multiplier.to_f
      end

      def self.flat_distance(origin_lat, origin_lng, lat, lng, lat_degree_units, lng_degree_units)
        Math.sqrt(
          (( lat_degree_units.to_f * ( origin_lat.to_f - lat.to_f )) ** 2) + 
          (( lng_degree_units.to_f * ( origin_lng.to_f - lng.to_f )) ** 2)
        )
      end

    end
  end
end

ActiveRecord::Base.connection.raw_connection.create_function( 'geokit_sphere_distance', 5 ) do |func, origin_lat, origin_lng, lat, lng, multiplier| 
  func.result = Geokit::Adapters::SQLite.sphere_distance(origin_lat, origin_lng, lat, lng, multiplier)
end

ActiveRecord::Base.connection.raw_connection.create_function( 'geokit_flat_distance', 6 ) do |func, origin_lat, origin_lng, lat, lng, lat_degree_units, lng_degree_units| 
  func.result = Geokit::Adapters::SQLite.flat_distance(origin_lat, origin_lng, lat, lng, lat_degree_units, lng_degree_units)
end
