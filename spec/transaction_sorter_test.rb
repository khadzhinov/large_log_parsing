require 'rspec'
require_relative '../transaction_sorter'

describe TransactionSorter do
  let(:input_file) { 'spec/fixtures/transactions.txt' }
  let(:output_file) { 'spec/fixtures/sorted_transactions.txt' }
  let(:sorter) { TransactionSorter.new(input_file, output_file) }

  before do
    File.write(input_file, <<~DATA)
      2023-09-03T12:45:00Z,txn12345,user987,500.25
      2023-09-03T12:45:01Z,txn12346,user988,300.50
      2023-09-03T12:45:02Z,txn12347,user989,700.75
    DATA
  end

  after do
    File.delete(input_file) if File.exist?(input_file)
    File.delete(output_file) if File.exist?(output_file)
  end

  it 'sorts transactions by amount in descending order' do
    sorter.sort_transactions

    sorted_lines = File.readlines(output_file).map(&:chomp)
    amounts = sorted_lines.map { |line| Transaction.new(*line.split(',')).amount }

    expect(amounts).to eq(amounts.sort.reverse)
  end
end
