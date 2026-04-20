// algorithms/dfs.js
// Depth-First Search Algorithm Implementation

export function dfs(grid, startNode, finishNode) {
  const visitedNodesInOrder = [];
  const stack = [startNode];
  startNode.isVisited = true;
  visitedNodesInOrder.push(startNode);

  while (stack.length > 0) {
    const currentNode = stack.pop();
    
    // If we reached the finish node, reconstruct the path
    if (currentNode === finishNode) {
      return visitedNodesInOrder;
    }

    // Get all unvisited neighbors
    const unvisitedNeighbors = getUnvisitedNeighbors(currentNode, grid);
    
    for (const neighbor of unvisitedNeighbors) {
      if (!neighbor.isVisited && !neighbor.isWall) {
        neighbor.isVisited = true;
        neighbor.previousNode = currentNode;
        visitedNodesInOrder.push(neighbor);
        stack.push(neighbor);
      }
    }
  }

  return visitedNodesInOrder;
}

function getUnvisitedNeighbors(node, grid) {
  const neighbors = [];
  const { col, row } = node;
  
  // Add neighbors in order: top, right, bottom, left
  if (row > 0) neighbors.push(grid[row - 1][col]);
  if (col < grid[0].length - 1) neighbors.push(grid[row][col + 1]);
  if (row < grid.length - 1) neighbors.push(grid[row + 1][col]);
  if (col > 0) neighbors.push(grid[row][col - 1]);
  
  return neighbors.filter(neighbor => !neighbor.isVisited);
}

// Backtrack from the finishNode to find the shortest path
export function getNodesInShortestPathOrderDFS(finishNode) {
  const nodesInShortestPathOrder = [];
  let currentNode = finishNode;
  
  while (currentNode !== null) {
    nodesInShortestPathOrder.unshift(currentNode);
    currentNode = currentNode.previousNode;
  }
  
  return nodesInShortestPathOrder;
}