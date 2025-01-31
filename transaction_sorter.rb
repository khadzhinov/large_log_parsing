require 'tempfile'

class Transaction
  attr_accessor :timestamp, :transaction_id, :user_id, :amount

  def initialize(timestamp, transaction_id, user_id, amount)
    @timestamp = timestamp
    @transaction_id = transaction_id
    @user_id = user_id
    @amount = amount.to_f
  end
end

class TransactionSorter
  def initialize(input_file, output_file)
    @input_file = input_file
    @output_file = output_file
  end

  def sort_transactions
    chunk_files = []

    File.open(@input_file, 'r') do |file|
      chunk = []
      file.each_line do |line|
        transaction = parse_transaction(line)
        chunk << transaction
        if chunk.size >= 10_000
          chunk_files << sort_and_write_chunk(chunk)
          chunk = []
        end
      end
      chunk_files << sort_and_write_chunk(chunk) unless chunk.empty?
    end

    merge_sorted_files(chunk_files)
  end

  private

  def parse_transaction(line)
    timestamp, transaction_id, user_id, amount = line.chomp.split(',')
    Transaction.new(timestamp, transaction_id, user_id, amount)
  end

  def sort_and_write_chunk(chunk)
    sorted_chunk = merge_sort(chunk)
    temp_file = Tempfile.new('sorted_chunk')
    File.open(temp_file.path, 'w') do |file|
      sorted_chunk.each do |transaction|
        file.puts "#{transaction.timestamp},#{transaction.transaction_id},#{transaction.user_id},#{transaction.amount}"
      end
    end
    temp_file.path
  end

  def merge_sort(array)
    return array if array.length <= 1

    mid = array.length / 2
    left = merge_sort(array[0...mid])
    right = merge_sort(array[mid...array.length])
    merge(left, right)
  end

  def merge(left, right)
    sorted = []
    while left.any? && right.any?
      if left.first.amount < right.first.amount
        sorted << right.shift
      else
        sorted << left.shift
      end
    end
    sorted.concat(left).concat(right)
  end

  def merge_sorted_files(chunk_files)
    File.open(@output_file, 'w') do |output_file|
      file_handles = chunk_files.map { |file| File.open(file, 'r') }
      min_heap = []

      file_handles.each_with_index do |file, index|
        line = file.gets
        min_heap << [line, index] if line
      end

      until min_heap.empty?
        min_heap.sort_by! { |line, _| -Transaction.new(*line.chomp.split(',')).amount }
        smallest_line, smallest_index = min_heap.shift
        output_file.puts smallest_line
        new_line = file_handles[smallest_index].gets
        min_heap << [new_line, smallest_index] if new_line
      end

      file_handles.each(&:close)
    end
  end
end

input_file = 'transactions.txt'
output_file = 'sorted_transactions.txt'
sorter = TransactionSorter.new(input_file, output_file)
sorter.sort_transactions
