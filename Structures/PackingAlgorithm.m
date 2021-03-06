function [components,structures,needExpand,isFit] = PackingAlgorithm(components,structures,structuresIndices,genParameters)
% Function that packs the components on a panel using the Sleator
% algorithm.

% Convert the components from their shapes to rectangles in order to be
% compatible with the packing algorithm
[rectangleDim,rectangleMass] = ComponentConversionForPacking(components);

% Convert the structures so that they are initially in the 'YZ' plane to
% work with the packing algorithm
[panelWidth,panelHeight,panelLength] = StructuresConversionForPacking(structures(structuresIndices(1)).Surface(structuresIndices(2)));

% Use the limited Sleator Packing Algorithm.
[rectangleCG,rectangleDim,needExpand,isFit] = SleatorPacking_Limitless(rectangleDim,rectangleMass,genParameters.tolerance,abs(panelWidth(2)-panelWidth(1)),abs(panelLength(2)-panelLength(1)),panelHeight(2)-panelHeight(1));      

% Here the CG of the components is rotated into its location.
[rectangleCG,rotationMatrix,needExpand] = CGconversionFromAlgorithm(rectangleCG,structures(structuresIndices(1)).Surface(structuresIndices(2)),panelWidth,panelHeight,panelLength,needExpand);

% Convert from Algorithm Format to the original format by rotating the
% components around and converting back to the original shapes. But only
% components that were fitted
components(isFit) = ComponentsConversionFromAlgorithm(rectangleCG,rectangleDim,components(isFit),rotationMatrix);


function [panelWidth,panelHeight,panelLength] = StructuresConversionForPacking(surface)
% A function to get the information from the panel structure and convert it
% into something more easily read by the packing algorithm. The packing
% algorithm doesn't take what plane the panels are in into account, it just
% assumes that they are on the YZ plane with a normal face in the X
% direction. This helps accomplish that task by converting panels in
% different planes to the same format.
%   Inputs:
%       surface             The surface of the structure that the
%                           components have been assigned to.
%
%   Outputs:
%       panelWidth          the "Width" of the panel, the base dimension of
%                           the panel if it were stood up with a normal
%                           vector along the +X direction.
%       panelHeight         the "Height" of the panel, the height dimension of
%                           the panel if it were stood up with a normal
%                           vector along the +X direction.
%       panelLength         the "Length" of the panel, the allowable
%                           distance away from the panel that the components can reach the most
%                           of (e.g., a component that can fit within the height and width of
%                           the panel but is extremely large in the other dimension might not
%                           fit.

if strcmp(surface.buildableDir,'XZ')
    if strcmp(surface.normalFace,'+Y')
        panelWidth = -surface.availableX;
    else
        panelWidth = surface.availableX;
    end
    panelHeight = surface.availableZ;
    panelLength = surface.availableY;
elseif strcmp(surface.buildableDir,'YZ')
    panelWidth = surface.availableY;
    panelHeight = surface.availableZ;
    panelLength = surface.availableX;
elseif strcmp(surface.buildableDir,'XY')
    panelWidth = surface.availableX;
    panelHeight = surface.availableY;
    panelLength = surface.availableZ;
end



function [rectangleCG,rotationMatrix,needExpand] = CGconversionFromAlgorithm(rectangleCG,structures,panelWidth,panelHeight,panelLength,needExpand)
% Edit the CG of the components to reflect the location of the panels. If it is on the YZ
% plane, then it should be fine, but then if it is along the XZ or XY
% plane, rotate the CG's of the components to reflect the new location.
% Certain CGs have to be flipped along certain axes in order to be placed
% correctly depending on the the original normal vectors of the panels.

rotationMatrix = RotateFrameToAxes(structures.normalFace,0);
% rotationMatrix = RotateFrameToAxes('-X',0);

% Flip the location depending on the components depending on the code.

% Check to see if the Y goes in the negative direction
% if ~isempty(strfind(structures.normalFace,'X')) % This doesn't stand for the Y axis.
if abs(panelWidth(2)) >= abs(panelWidth(1)) && panelWidth(2) < panelWidth(1)
    if ~strcmp(structures.normalFace,'+Z')
        % This is only necessary if the normal face isn't in the Z axis.
        rectangleCG(:,2) = -rectangleCG(:,2);
    end
end

% Check To see if the Z goes in the negative direction
if abs(panelHeight(2)) >= abs(panelHeight(1)) && panelHeight(2) < panelHeight(1)
    rectangleCG(:,3) = rectangleCG(:,3);
end

% Check to see if the X goes in the negative direction
if abs(panelLength(2)) >= abs(panelLength(1)) && panelLength(2) < panelLength(1)
    if strcmp(structures.normalFace,'+Y') || strcmp(structures.normalFace,'-X')
        rectangleCG(:,1) = -rectangleCG(:,1);
    end
end
% Rotate the center of gravity of the locations
rectangleCG = (rotationMatrix*rectangleCG')';

% Add the center of gravities to the first places that a satellite can fit
% it on that panel
rectangleCG(:,1) = rectangleCG(:,1) + structures.availableX(1);
rectangleCG(:,2) = rectangleCG(:,2) + structures.availableY(1);
rectangleCG(:,3) = rectangleCG(:,3) + structures.availableZ(1);

% Place the expansion variables in the right entries of the needExpand
% vector so that it turns out to be [Height, Width, Length]
if strcmp(structures.buildableDir,'XY')
    expandHeight = needExpand(4);
    expandWidth = needExpand(3);
    expandLength = needExpand(2);
elseif strcmp(structures.buildableDir,'XZ')
    expandHeight = needExpand(2);
    expandWidth = needExpand(4);
    expandLength = needExpand(3);
elseif strcmp(structures.buildableDir,'YZ')
    expandHeight = needExpand(2);
    expandWidth = needExpand(3);
    expandLength = needExpand(4);
else
    expandHeight = 0;
    expandWidth = 0;
    expandLength = 0;
end

needExpand(2) = expandHeight + structures.availableZ(1);
needExpand(3) = expandWidth;
needExpand(4) = expandLength;



function [rectangleDim,rectangleMass] = ComponentConversionForPacking(components)
% Converts allocated components into a format useable by the algorithm
% Assumes that the component will be mounted along it's 'zy' axis.
% rectangleDim = [h, w, l]
% rectangleMass = [m]

nr = length(components);
rectangleDim = zeros(nr,3);
rectangleMass = zeros(nr,1);
for i = 1:nr
    % If it is a sphere
    if strcmp(components(i).Shape,'Rectangle')
        h = components(i).Dim(1);
        w = components(i).Dim(2);
        l = components(i).Dim(3);
    elseif strcmp(components(i).Shape,'Sphere')
        r = components(i).Dim;
        h = 2*r;
        w = 2*r;
        l = 2*r;
    elseif strcmp(components(i).Shape,'Cone')
        h = components(i).Dim(1);
        r1 = components(i).Dim(2);
        r2 = components(i).Dim(3);
        if r1 > r2
            l = r1*2;
            w = r1*2;
        else
            l = r2*2;
            w = r2*2;
        end
    % If it is a cylinder
    elseif strfind(components(i).Shape,'Cylinder')
        h = components(i).Dim(1);
        r = components(i).Dim(2);
        w = 2*r;
        l = 2*r;
    end
    rectangleDim(i,:) = [h,w,l];
    rectangleMass(i) = components(i).Mass;
end

function components = ComponentsConversionFromAlgorithm(rectangleCG,rectangleDim,components,rotationMatrix)
% Since the CG has already been placed into location, this takes the
% components that were transformed into rectangles to work with the packing
% algorithm and returns them to their original shape, along with their
% necessary rotation matrix to go from their component body axes to the
% satellite body axis.

n1 = size(rectangleCG,1);

for i = 1:n1
    components(i).RotateToSatBodyFrame = rotationMatrix;
    if strfind(components(i).Shape,'Rectangle')
    % In order to plot rectangular prisms, the code needs to know where all the
    % vertices are.
        h = rectangleDim(i,1);
        w = rectangleDim(i,2);
        l = rectangleDim(i,3);
        components(i).Dim = [h,w,l];
        components(i).CG_XYZ = rectangleCG(i,:); % No need to rotate the CGs again, as they have already been rotated.
        xyzVertices = [-l/2 -w/2 -h/2; 
                    -l/2 w/2 -h/2; 
                    l/2 w/2 -h/2; 
                    l/2 -w/2 -h/2; 
                    -l/2 -w/2 h/2;
                    -l/2 w/2 h/2; 
                    l/2 w/2 h/2; 
                    l/2 -w/2 h/2];
        xyzVertices = (components(i).RotateToSatBodyFrame*xyzVertices')';
        
        X = ones(8,1)*components(i).CG_XYZ(1);
        Y = ones(8,1)*components(i).CG_XYZ(2);
        Z = ones(8,1)*components(i).CG_XYZ(3);
        components(i).Vertices =  xyzVertices + [X,Y,Z];
    elseif strfind(components(i).Shape,'Sphere')
        h = rectangleDim(i,1);
        r = h/2;
        components(i).Dim = r;
        components(i).CG_XYZ = rectangleCG(i,:);
    elseif strfind(components(i).Shape,'Cone')
        r1 = components(i).Dim(2);
        r2 = components(i).Dim(3);
        if r1 > r2
            l = r1*2;
            w = r1*2;
        else
            l = r2*2;
            w = r2*2;
        end
        components(i).CG_XYZ = rectangleCG(i,:);
    elseif strfind(components(i).Shape,'Cylinder')
        % Need to find a way to record the height and the width here.
        h = components(i).Dim(1);
        r = components(i).Dim(2);
        w = 2*r;
        l = 2*r;
        components(i).Dim = [h,r];
        components(i).CG_XYZ = rectangleCG(i,:);
    end
end


