RSpec.describe Aquaduct do
  RSpec::Matchers.define :define_const do |const|
    match do |mod|
      mod.const_defined? const
    end
  end

  it 'includes Package and PackageChanneler' do
    with_channels

    expect(@module).to define_const :Package
    expect(@module).to define_const :PackageChanneler
  end

  it 'include Custom and CustomChanneler given custom entity' do
    with_channels :custom

    expect(@module).to define_const :Custom
    expect(@module).to define_const :CustomChanneler
  end

  it 'exposes channel method from channeler' do
    with_channels
    expect(@package_channeler_class).to receive(:channel).with :foo
    @module.channel :foo
  end

  it 'accepts custom model' do
    class CustomModel
      include ActiveModel::Model
      attr_accessor :id, :channel
    end

    with_channels CustomModel do
      advance_through %i[channeled]
    end
    channeled = @module.channel spy, @package_class.channeled

    expect(@module).to define_const :CustomModel
    expect(@module).to define_const :CustomModelChanneler
    expect(channeled.all.first).to be_a CustomModel
  end

  def with_channels *a, **kw, &b
    @module = Module.new do
      include(TestableAquaduct.with_channels *a, **kw, &b)
    end
    @entity_name = @module.const_get :EntityName
    entity = @entity_name.to_s.camelize.to_sym
    @package_class = @module.const_get entity
    @package_channeler_class = @module.const_get :"#{entity}Channeler"
  end
end
