// algorithms/astar.js
// A* Algorithm Implementation

export function astar(grid, startNode, finishNode) {
  const visitedNodesInOrder = [];
  
  // Initialize all nodes for A*
  for (const row of grid) {
    for (const node of row) {
      node.distance = Infinity;
      node.heuristicDistance = 0;
      node.totalDistance = Infinity;
      node.isVisited = false;
      node.previousNode = null;
    }
  }
  
  startNode.distance = 0;
  startNode.heuristicDistance = manhattanDistance(startNode, finishNode);
  startNode.totalDistance = startNode.heuristicDistance;
  
  const unvisitedNodes = getAllNodes(grid);

  while (!!unvisitedNodes.length) {
    sortNodesByTotalDistance(unvisitedNodes);
    const closestNode = unvisitedNodes.shift();
    
    // If we encounter a wall, we skip it.
    if (closestNode.isWall) continue;
    
    // If the closest node is at a distance of infinity,
    // we must be trapped and should therefore stop.
    if (closestNode.distance === Infinity) return visitedNodesInOrder;
    
    closestNode.isVisited = true;
    visitedNodesInOrder.push(closestNode);
    
    if (closestNode === finishNode) return visitedNodesInOrder;
    
    updateUnvisitedNeighbors(closestNode, grid, finishNode);
  }
  
  return visitedNodesInOrder;
}

function sortNodesByTotalDistance(unvisitedNodes) {
  unvisitedNodes.sort((nodeA, nodeB) => nodeA.totalDistance - nodeB.totalDistance);
}

function updateUnvisitedNeighbors(node, grid, finishNode) {
  const unvisitedNeighbors = getUnvisitedNeighbors(node, grid);
  for (const neighbor of unvisitedNeighbors) {
    // Use the neighbor's weight for distance calculation
    const tentativeDistance = node.distance + neighbor.weight;
    
    // Only update if we found a better path
    if (tentativeDistance < neighbor.distance) {
      neighbor.distance = tentativeDistance;
      neighbor.heuristicDistance = manhattanDistance(neighbor, finishNode);
      neighbor.totalDistance = neighbor.distance + neighbor.heuristicDistance;
      neighbor.previousNode = node;
    }
  }
}

function getUnvisitedNeighbors(node, grid) {
  const neighbors = [];
  const { col, row } = node;
  
  if (row > 0) neighbors.push(grid[row - 1][col]);
  if (row < grid.length - 1) neighbors.push(grid[row + 1][col]);
  if (col > 0) neighbors.push(grid[row][col - 1]);
  if (col < grid[0].length - 1) neighbors.push(grid[row][col + 1]);
  
  return neighbors.filter(neighbor => !neighbor.isVisited);
}

function getAllNodes(grid) {
  const nodes = [];
  for (const row of grid) {
    for (const node of row) {
      nodes.push(node);
    }
  }
  return nodes;
}

function manhattanDistance(nodeA, nodeB) {
  return Math.abs(nodeA.row - nodeB.row) + Math.abs(nodeA.col - nodeB.col);
}

export function getNodesInShortestPathOrderAStar(finishNode) {
  const nodesInShortestPathOrder = [];
  let currentNode = finishNode;
  while (currentNode !== null) {
    nodesInShortestPathOrder.unshift(currentNode);
    currentNode = currentNode.previousNode;
  }
  return nodesInShortestPathOrder;
}