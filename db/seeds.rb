10.times do
  Temperature.create sensor: 'attic', celsius: [*20..40].sample
  Temperature.create sensor: 'living_room', celsius: [*20..40].sample
end
