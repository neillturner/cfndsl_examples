path = 'run.bat'
path2 = 'run.new'
lines = IO.readlines(path).map do |line|
  values = line.split(" ")
  filesplit = values[2].split(".")
  line = values[0]+" "+values[1]+" "+values[2] + " -o "+filesplit[0]+".rb"
end
File.open(path2, 'w') do |file|
  file.puts lines
end