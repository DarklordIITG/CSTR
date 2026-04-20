// Node/Node.jsx
import React, { Component } from 'react';
import './Node.css';

export default class Node extends Component {
  render() {
    const {
      col,
      isFinish,
      isStart,
      isWall,
      weight,
      onMouseDown,
      onMouseEnter,
      onMouseUp,
      row,
    } = this.props;
    
    const extraClassName = isFinish
      ? 'node-finish'
      : isStart
      ? 'node-start'
      : isWall
      ? 'node-wall'
      : weight > 1
      ? 'node-weight'
      : '';

    const nodeStyle = {};
    if (weight > 1 && !isWall && !isStart && !isFinish) {
      const weightColors = {
        2: '#fff3cd',
        3: '#ffeaa7', 
        4: '#fdcb6e',
        5: '#e17055'
      };
      nodeStyle.backgroundColor = weightColors[weight] || '#fff3cd';
    }

    return (
      <div
        id={`node-${row}-${col}`}
        className={`node ${extraClassName}`}
        style={nodeStyle}
        onMouseDown={(e) => {
          e.preventDefault();
          onMouseDown(row, col);
        }}
        onMouseEnter={() => onMouseEnter(row, col)}
        onMouseUp={() => onMouseUp()}
        onContextMenu={(e) => e.preventDefault()} // Prevent right-click menu
      >
        {weight > 1 && !isWall && !isStart && !isFinish && weight}
      </div>
    );
  }
}