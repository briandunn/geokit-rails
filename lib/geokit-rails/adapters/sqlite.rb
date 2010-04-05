module Geokit
  module Adapters
    class SQLite < Abstract
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
    end
  end
end

ActiveRecord::Base.connection.raw_connection.create_function( 'geokit_sphere_distance', 5 ) do |func, origin_lat, origin_lng, lat, lng, multiplier| 
  to_rad = proc do |degrees|
    degrees.to_f / 180.0 * Math::PI
  end
    func.result = Math.acos( 
      [
        1.0,
        Math.cos(origin_lat) * Math.cos(origin_lng) * Math.cos(to_rad.call(lat)) * Math.cos(to_rad.call(lng)) + 
        Math.cos(origin_lat) * Math.sin(origin_lng) * Math.cos(to_rad.call(lat)) * Math.sin(to_rad.call(lng)) +
        Math.sin(origin_lat) * Math.sin(to_rad.call(lat))
      ].min
    ) * multiplier.to_f
end

ActiveRecord::Base.connection.raw_connection.
  create_function( 'geokit_flat_distance', 6 ) do |func, origin_lat, origin_lng, lat, lng, lat_degree_units, lng_degree_units| 
    func.result = Math.sqrt((( lat_degree_units.to_f * (origin_lat.to_f - lat.to_f) ) ** 2) + ((lng_degree_units.to_f * ( origin_lng.to_f - lng.to_f ))**2))
end
