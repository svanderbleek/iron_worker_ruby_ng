require_relative 'helpers'

class WorkerTest < IWNGTest

  def self.startup
    puts 'Please, input cluster:'
    @@cluster = gets.chomp
    @@cluster = 'default' if @@cluster == ''
  end

  def test_concurrency
    puts "Starting concurrency tests for \"#{@@cluster}\" cluster..."
    max_concurrency = gets_in('Please, input maximum concurrency (5 for default cluster):', 5)
    code_id = client.codes.create(IronWorkerNG::Code::Base.new('test/sleep'), {max_concurrency: max_concurrency}).id
    tasks = []
    (max_concurrency * 2).times do
      tasks.push client.tasks.create('sleep', {:sleep => 1200}, {cluster: @@cluster}).id
    end

    sleep 120
    running = 0
    queued = 0
    tasks.each do |task|
      task_status = client.tasks.get(task).status
      running +=1 if task_status == 'running'
      queued +=1 if task_status == 'queued'
    end
    client.tasks.cancel_all(code_id)

    assert_equal max_concurrency, running
    assert_equal max_concurrency, queued

  end

  def test_workers
    stats = ''
    test_workers = Dir.entries('test/worker-test/') - %w(. ..)
    puts "Starting MEM, CPU, HDD, Network tests for \"#{@@cluster}\"..."
    mem_mb = gets_in('Please, input maximum available memory size in MB (320 for default cluster):', 320)
    hdd_mb = gets_in('Please, input maximum available HDD size in MB (10000 for default cluster):', 10000)
    cpu = gets_in('Please, input CPU performance: "high" - 1, "medium" - 2, "low" - 3  (2 - for default cluster):', 2)
    test_workers.each do |test_worker|
      client.codes.create(IronWorkerNG::Code::Base.new("test/worker-test/#{test_worker}/#{test_worker}"))
      id = client.tasks.create(test_worker, {max_mem: mem_mb, max_hdd: hdd_mb, cpu: cpu}, {cluster: @@cluster}).id
      task = client.tasks.wait_for(id)

      if test_worker == 'mem-kill'
        assert_equal 'error', task.status
        assert_equal "ERROR: WORKER RAM LIMIT EXCEEDED (#{mem_mb}M)", task.msg
      else
        assert_equal 'complete', task.status
      end
      stats = client.tasks.log(id) if test_worker == 'stat'
    end
    puts "\n\n======================WORKER INFO===================="
    puts stats
  end

  def gets_in(msg, default)
    puts msg
    input = gets
    return input.to_i if !!Integer(input) rescue false
    return default if input.chomp == ''
    puts 'That is not an integer'
    gets_in(msg, default)
  end
end
