function [prev_img, next_img] = adj_image_list(index, listing, directory, offsets)
    % Listing must be sorted in ascending order!
    % First, split into positive and negative offsets
    positive_offsets = offsets(offsets > 0);
    negative_offsets = offsets(offsets < 0);
    % Then build list
    prev_img = build_list(negative_offsets + index, listing, directory);
    next_img = build_list(positive_offsets + index, listing, directory);
end

function output = build_list(to_search, listing, directory)
    output = {};
    % length of directory_listing
    listing_length = length(listing);
    % Loop through to_search
   for x = 1:length(to_search)
       % First, verify that this index is within bounds
       if to_search(x) >= 1 && to_search(x) <= listing_length
           output = [output; fullfile(directory, listing(to_search(x)))]; 
       end
   end
end