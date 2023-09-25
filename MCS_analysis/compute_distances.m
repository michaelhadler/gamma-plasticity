%compute distances MCS

%computes distances of MEA electrodes given
    % channel list (double)
    % x-values (µm)
    % y-values (µm)
    % rule:
        % cartesian: distances between all electrodes are calculated
        % according to pythagorean geometry: d² = sqrt(x²+y²) with pdist (Statistics and Machine Learning Toolbox)
        % neighbours: electrodes are arranged as a graph-object and
        % cartesian distances computed at edges between direct "neighbors" only (applicable
        % only to fixed-channel MEAs) and passed to shortestpath function.
        % Requires passed variable 'electrode_distance' (default 200 µm)
        % proximities: for each electrode, edges are assumed between
        % electrodes in proximity (value given in µm as 'ProximityVal', default 200 µm) and
        % distances calculated with shortestpath

function distance_matrix = compute_distances(x,y,rule,varargin)

dist_elec = 200;
dist_calc = 200;

while ~isempty(varargin)
    switch lower(varargin{1})
        case 'proximityval'
            dist_calc = varargin{2} ;
        case 'electrode_distance'
            dist_elec = varargin{2} ;
          otherwise
              error(['Unexpected option: ' varargin{1}])
     end
     varargin(1:2) = [];
end

if rule == 'cartesian'
    
    xy_matrix = [x y];
    distance_matrix = squareform(pdist(xy_matrix));

elseif rule == 'neighbors'

    %Compute cartesian distances
    xy_matrix = [x y];
    distance_matrix = squareform(pdist(xy_matrix));
    
    %Create graph: Edges between neighboring electrodes
    cut_off = sqrt(dist_elec^2 + dist_elec^2);
    connections = distance_matrix;
    connections(distance_matrix>cut_off)=0;
    connections_graph = graph(connections);
    distance_matrix = distances(connections_graph);

elseif rule == 'proximities'

    %Compute cartesian distances
    xy_matrix = [x y];
    distance_matrix = squareform(pdist(xy_matrix));
    %Create graph: Edges between electrodes in proximity (< 200 µm)
    connections = distance_matrix;
    connections(distance_matrix>=dist_calc)=0;
    connections_graph = graph(connections);
    distance_matrix = distances(connections_graph);

end