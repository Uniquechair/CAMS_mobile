import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController _heroCtrl = PageController();
  final PageController _roomsCtrl = PageController(viewportFraction: 0.88);

  int _heroIndex = 0;
  int _roomsIndex = 0;

  // ----- demo content (swap with live data later) -----
  final _heroSlides = const [
    _HeroData(
      image: 'images/cams_banner.png',
      smallTitle: 'YOUR JOURNEY',
      bigTitle: 'Bako National Park',
      desc:
          'Sarawak’s oldest national park with mangroves, proboscis monkeys, and coastal trails.',
      ctaLabel: 'See more',
    ),
    _HeroData(
      image: 'images/cams_feature1.png',
      smallTitle: 'WILDLIFE',
      bigTitle: 'Semenggoh Wildlife Centre',
      desc: 'Meet rehabilitated orangutans in a protected habitat.',
      ctaLabel: 'See more',
    ),
    _HeroData(
      image: 'images/cams_feature2.png',
      smallTitle: 'CAVES',
      bigTitle: 'Niah National Park',
      desc: 'Prehistoric caves, rainforest treks, and rich biodiversity.',
      ctaLabel: 'See more',
    ),
  ];

  final _destinations = const [
    _DestData(
      title: 'Wind Cave Nature Reserve',
      location: 'Bau, Sarawak',
      image: 'images/cams_feature3.png',
      blurb:
          'Cool limestone caves with narrow passages and bats—great for short eco visits.',
    ),
    _DestData(
      title: 'Damai Beach',
      location: 'Teluk Bandung, Santubong',
      image: 'images/cams_feature4.png',
      blurb:
          'Golden sands & clear waters—perfect for swimming and sunsets.',
    ),
  ];

  final _trips = const [
    _TripData(
      title: 'Sarawak Cultural Village',
      image: 'images/cams_feature5.png',
      blurb: 'A “living museum” with traditional houses, crafts, and shows.',
    ),
    _TripData(
      title: 'Kubah National Park',
      image: 'images/cams_feature6.png',
      blurb: 'Waterfalls and lush trails—ideal for day hikes.',
    ),
    _TripData(
      title: 'Kuching Waterfront',
      image: 'images/cams_screenshot1.png',
      blurb: 'Scenic promenade with food, heritage, and night lights.',
    ),
    _TripData(
      title: 'Gunung Mulu National Park',
      image: 'images/cams_screenshot2.png',
      blurb: 'UNESCO site: cave systems, pinnacles, and rainforest.',
    ),
    _TripData(
      title: 'Annah Rais Longhouse',
      image: 'images/cams_screenshot3.png',
      blurb: 'Experience Bidayuh culture in an authentic longhouse.',
    ),
    _TripData(
      title: 'Similajau National Park',
      image: 'images/cams_screenshot4.png',
      blurb: 'Golden beaches, mangroves, and coastal wildlife.',
    ),
  ];

  final _rooms = const [
    _RoomData(image: 'images/cams_screenshot5.png', label: 'Family Suite'),
    _RoomData(image: 'images/cams_screenshot6.png', label: 'Deluxe Room'),
    _RoomData(image: 'images/cams_screenshot1.png', label: 'Executive Suite'),
  ];
  // -----------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.of(context).size.width * 0.05; // responsive padding

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hello Sarawak'),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.person_outline)),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            children: [
              // HERO
              SizedBox(
                height: 320,
                child: Stack(
                  children: [
                    PageView.builder(
                      controller: _heroCtrl,
                      onPageChanged: (i) => setState(() => _heroIndex = i),
                      itemCount: _heroSlides.length,
                      itemBuilder: (_, i) => _HeroSlide(slide: _heroSlides[i]),
                    ),
                    Positioned(
                      bottom: 12,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _heroSlides.length,
                          (i) => Container(
                            width: i == _heroIndex ? 24 : 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: i == _heroIndex
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.white70,
                              borderRadius: BorderRadius.circular(50),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // POPULAR DESTINATIONS
              _SectionHeader(
                title: 'Popular Destinations',
                subtitle: 'Tours let you see a lot in a short time',
                padding: EdgeInsets.symmetric(horizontal: pad),
              ),
              SizedBox(
                height: 350,
                child: ListView.separated(
                  padding: EdgeInsets.symmetric(horizontal: pad),
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (_, i) => _DestinationCard(data: _destinations[i]),
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemCount: _destinations.length,
                ),
              ),

              const SizedBox(height: 8),

              // POPULAR TRIPS
              _SectionHeader(
                title: 'Popular Trips',
                subtitle: 'Find your path, create your memories',
                padding: EdgeInsets.symmetric(horizontal: pad),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: pad),
                child: LayoutBuilder(
                  builder: (context, c) {
                    final cross = c.maxWidth > 700
                        ? 3
                        : c.maxWidth > 500
                            ? 2
                            : 1; // responsive columns
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cross,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        mainAxisExtent: 310,
                      ),
                      itemCount: _trips.length,
                      itemBuilder: (_, i) => _TripCard(data: _trips[i]),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // ROOMS & SUITES
              _SectionHeader(
                title: 'Rooms & Suites',
                subtitle: 'Rest is for going further',
                padding: EdgeInsets.symmetric(horizontal: pad),
              ),
              SizedBox(
                height: 220,
                child: PageView.builder(
                  controller: _roomsCtrl,
                  onPageChanged: (i) => setState(() => _roomsIndex = i),
                  itemCount: _rooms.length,
                  itemBuilder: (_, i) => _RoomSlide(room: _rooms[i]),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _rooms.length,
                  (i) => Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: i == _roomsIndex
                          ? Theme.of(context).colorScheme.primary
                          : Colors.black26,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // CONTACT US
              _SectionHeader(
                title: 'Contact Us',
                subtitle: null,
                padding: EdgeInsets.symmetric(horizontal: pad),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: pad, vertical: 8),
                child: _ContactBlock(
                  onOpenMap: () => _openMaps(1.7365, 110.3403, 'Damai Beach'),
                ),
              ),

              const SizedBox(height: 24),

              // FOOTER
              Padding(
                padding: EdgeInsets.symmetric(horizontal: pad, vertical: 24),
                child: Text(
                  '© ${DateTime.now().year} Hello Sarawak • Your Journey Begins',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openMaps(double lat, double lng, String label) async {
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng($label)');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      final geo = Uri.parse('geo:$lat,$lng?q=$lat,$lng($label)');
      await launchUrl(geo, mode: LaunchMode.externalApplication);
    }
  }
}

// ================= Models =================
class _HeroData {
  final String image, smallTitle, bigTitle, desc, ctaLabel;
  const _HeroData({
    required this.image,
    required this.smallTitle,
    required this.bigTitle,
    required this.desc,
    required this.ctaLabel,
  });
}

class _DestData {
  final String title, location, image, blurb;
  const _DestData({
    required this.title,
    required this.location,
    required this.image,
    required this.blurb,
  });
}

class _TripData {
  final String title, image, blurb;
  const _TripData({required this.title, required this.image, required this.blurb});
}

class _RoomData {
  final String image, label;
  const _RoomData({required this.image, required this.label});
}

// ================= Widgets =================
class _HeroSlide extends StatelessWidget {
  const _HeroSlide({required this.slide});
  final _HeroData slide;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(slide.image, fit: BoxFit.cover),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black.withValues(alpha: 0.55), Colors.transparent],
              ),
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(slide.smallTitle,
                  style: const TextStyle(
                      color: Colors.white70, fontWeight: FontWeight.w600, letterSpacing: 1)),
              const SizedBox(height: 6),
              Text(slide.bigTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  )),
              const SizedBox(height: 6),
              Text(slide.desc,
                  style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.3)),
              const SizedBox(height: 10),
              FilledButton(onPressed: () {}, child: Text(slide.ctaLabel)),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.padding,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: padding.copyWith(top: 12, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(subtitle!, style: t.bodyMedium?.copyWith(color: Colors.black54)),
            ),
        ],
      ),
    );
  }
}

class _DestinationCard extends StatelessWidget {
  const _DestinationCard({required this.data});
  final _DestData data;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260, // slightly smaller so it fits neatly on mobile
      child: Card(
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: InkWell(
          onTap: () {},
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 👇 this ensures the image fully fills its space, no gaps or overflow
              AspectRatio(
                aspectRatio: 16 / 10,
                child: Image.asset(
                  data.image,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.place_outlined,
                            size: 16, color: Colors.black54),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            data.location,
                            style: const TextStyle(color: Colors.black54),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      data.blurb,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(height: 1.25),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          textStyle: const TextStyle(fontSize: 13),
                        ),
                        child: const Text('See more'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({required this.data});
  final _TripData data;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,          // 👈 important
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.asset(
              data.image,
              fit: BoxFit.cover,                 // 👈 fills the box cleanly
              width: double.infinity,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const SizedBox(height: 6),
                Text(
                  data.blurb,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.black87, height: 1.25, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomSlide extends StatelessWidget {
  const _RoomSlide({required this.room});
  final _RoomData room;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(room.image, fit: BoxFit.cover),
            Positioned(
              left: 12,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  room.label,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _ContactBlock extends StatelessWidget {
  const _ContactBlock({required this.onOpenMap});
  final VoidCallback onOpenMap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Map preview card (tap to open Google Maps)
        Card(
          child: InkWell(
            onTap: onOpenMap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // static image or screenshot; opening launches Maps
                      Image.asset('images/cams_logo.png', fit: BoxFit.cover),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: FilledButton.tonalIcon(
                            onPressed: onOpenMap,
                            icon: const Icon(Icons.directions),
                            label: const Text('Open in Maps'),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Damai Beach, Kuching'),
                      SizedBox(height: 4),
                      Text('Tap the map to open Google Maps.',
                          style: TextStyle(color: Colors.black54)),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Contact form UI (stub)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.mail_outline,
                        color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    const Text('Send Message',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 8),
                const _HintField(hint: 'Full Name'),
                const _HintField(hint: 'Email'),
                const _HintField(hint: 'Your message here', maxLines: 4),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {},   // TODO: connect to CAMS API
                    child: const Text('Send'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HintField extends StatelessWidget {
  const _HintField({required this.hint, this.maxLines = 1});
  final String hint;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
