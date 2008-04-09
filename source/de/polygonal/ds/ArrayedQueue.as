/**
 * Copyright (c) Michael Baczynski 2007
 * http://lab.polygonal.de/ds/
 *
 * This software is distributed under licence. Use of this software
 * implies agreement with all terms and conditions of the accompanying
 * software licence.
 */
package de.polygonal.ds {
	import de.polygonal.ds.Collection;	

	/**
	 * An arrayed queue (circular queue).
	 * <p>A queue is a FIFO structure (First In, First Out).</p>
	 */
	public class ArrayedQueue implements Collection
	{
		private var _que:Array;
		private var _size:int;
		private var _divisor:int;
		
		private var _count:int;
		private var _front:int;
		
		/**
		 * Initializes a queue object to match the given size.
		 * The size <b>must be a power of two</b> to use fast bitwise AND modulo.
		 * The size is rounded to the next largest power of 2.
		 * 
		 * @param size The size of the queue.
		 */
		public function ArrayedQueue(size:int)
		{
			init(size);
		}
		
		/**
		 * Indicates the front item.
		 * 
		 * @return The front item.
		 */
		public function peek():*
		{
			return _que[_front];
		}
		
		/**
		 * Enqueues some data.
		 * 
		 * @param  obj The data.
		 * @return True if operation succeeded, otherwise false (queue is full).
		 */
		public function enqueue(obj:*):Boolean
		{
			if (_size != _count)
			{
				_que[int((_count++ + _front) & _divisor)] = obj;
				return true;
			}
			return false;
		}
		
		/**
		 * Dequeues and returns the front item.
		 * 
		 * @return The front item or null if the queue is empty.
		 */
		public function dequeue():*
		{
			if (_count > 0)
			{
				var data:* = _que[_front++];
				if (_front == _size) _front = 0;
				_count--;
				return data;
			}
			return null;
		}
		
		/**
		 * Deletes the last dequeued item to free it
		 * for the garbage collector. Use only directly
		 * after calling the dequeue() function.
		 */
		public function dispose():void
		{
			if (!_front) _que[int(_size  - 1)] = null;
			else 		 _que[int(_front - 1)] = null;
		}
		
		/**
		 * Reads an item relative to the front index.
		 * 
		 * @param i The index of the item.
		 * @return The item at the given relative index.
		 */
		public function getAt(i:int):*
		{
			if (i >= _count) return null;
			return _que[int((i + _front) & _divisor)];
		}
		
		/**
		 * Writes an item relative to the front index.
		 * 
		 * @param i   The index of the item.
		 * @param obj The data.
		 */
		public function setAt(i:int, obj:*):void
		{
			if (i >= _count) return;
			_que[int((i + _front) & _divisor)] = obj;
		}
		
		/**
		 * Checks if a given item exists.
		 * 
		 * @return True if the item is found, otherwise false.
		 */
		public function contains(obj:*):Boolean
		{
			for (var i:int = 0; i < _count; i++)
			{
				if (_que[int((i + _front) & _divisor)] === obj)
					return true;
			}
			return false;
		}
		
		/**
		 * Clears all elements.
		 */
		public function clear():void
		{
			_que = new Array(_size);
			_front = _count = 0;
		}
		
		/**
		 * Creates a new iterator pointing to the front of the queue.
		 */
		public function getIterator():Iterator
		{
			return new ArrayedQueueIterator(this);
		}
		
		/**
		 * The total number of items in the queue.
		 */
		public function get size():int
		{
			return _count;
		}
		
		/**
		 * Checks if the queue is empty.
		 */
		public function isEmpty():Boolean
		{
			return _count == 0;
		}
		
		/**
		 * The maximum allowed size.
		 */
		public function get maxSize():int
		{
			return _size;
		}
		
		/**
		 * Converts the structure into an array.
		 * 
		 * @return An array.
		 */
		public function toArray():Array
		{
			var a:Array = new Array(_count);
			for (var i:int = 0; i < _count; i++)
				a[i] = _que[int((i + _front) & _divisor)];
			return a;
		}
		
		/**
		 * Returns a string representing the current object.
		 */
		public function toString():String
		{
			return "[ArrayedQueue, size=" + size + "]";
		}
		
		/**
		 * Prints out all elements in the queue (for debug/demo purposes).
		 */
		public function dump():String
		{
			var s:String = "[ArrayedQueue]\n";
			
			s += "\t" + getAt(i) + " -> front\n";
			for (var i:int = 1; i < _count; i++)
				s += "\t" + getAt(i) + "\n";
			
			return s;
		}
		
		private function init(size:int):void
		{
			//check if the size is a power of 2
			if (!(size > 0 && ((size & (size - 1)) == 0)))
			{
				//given a binary integer value x, the next largest power of 2 can be computed by a swar algorithm
				//that recursively "folds" the upper bits into the lower bits. this process yields a bit vector with
				//the same most significant 1 as x, but all 1's below it. adding 1 to that value yields the next
				//largest power of 2. for a 32-bit value
				size |= (size >> 1);
				size |= (size >> 2);
				size |= (size >> 4);
				size |= (size >> 8);
				size |= (size >> 16);
				size++;
			}
			_size = size;
			_divisor = size - 1;
			clear();
		}
	}
}

import de.polygonal.ds.ArrayedQueue;
import de.polygonal.ds.Iterator;

internal class ArrayedQueueIterator implements Iterator
{
	private var _que:ArrayedQueue;
	private var _cursor:int;
	
	public function ArrayedQueueIterator(que:ArrayedQueue)
	{
		_que = que;
		_cursor = 0;
	}
	
	public function get data():*
	{
		return _que.getAt(_cursor);
	}
	
	public function set data(obj:*):void
	{
		_que.setAt(_cursor, obj);
	}
	
	public function start():void
	{
		_cursor = 0;
	}
	
	public function hasNext():Boolean
	{
		return _cursor < _que.size;
	}
	
	public function next():*
	{
		if (_cursor < _que.size)
			return _que.getAt(_cursor++);
		return null;
	}
}